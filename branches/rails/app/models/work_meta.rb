class WorkMeta < AltoModel
  set_table_name 'WORKS_META'
  set_primary_key 'WORK_ID'
  has_many :items, :foreign_key=>"WORK_ID"
  has_many :titles, :foreign_key=>"WORK_ID"
  has_many :collections, :through=>:titles
  has_many :holdings, :foreign_key=>"WORK_ID"
  attr_accessor :has_collections
  alias :identifier :id

  def title
    generate_content unless @content
    title = nil
    if @content
      if @content['245'] && @content['245']['a']
        return @content['245']['a']
      end
    else
      w = Work.find_by_WORK_ID(self.WORK_ID)
      if w && w.TITLE_DISPLAY
        return w.TITLE_DISPLAY.sub(/^\. \-/,'')
      end
    end
    "Title not available"
  end
  
  def marc_content(format)
    generate_content unless @content
    return unless @content
    if format == 'marc'
      @content.to_marc
    else
      @content.to_xml.to_s
    end
  end
  
  def to_marc
    MARC::Record.new_from_marc(self.RAW_DATA).to_marc if self.RAW_DATA
  end
  
  def to_marcxml    
    MARC::Record.new_from_marc(self.RAW_DATA).to_xml if self.RAW_DATA
  end

  def to_mods
    to_marcxml
  end
  
  def to_dc
    to_marcxml
  end  
  
  def to_oai_dc
    to_marcxml
  end  
  
  def categories
    unless self.SUPPRESS_FROM_OPAC == 'T' or self.SUPPRESS_FROM_INDEX == 'T'
      return ['opac']
    end
  end
  
  def updated
    self.MODIFIED_DATE.xmlschema if self.MODIFIED_DATE
  end
  
  def relationships
    relationships = nil
    if self.items or self.has_collections
      relationships = {}
      if self.items && !self.items.empty?
        relationships['http://jangle.org/vocab/Entities#Item'] = "#{self.uri}/items/"
      end
      if self.has_collections
        relationships['http://jangle.org/vocab/Entities#Collection'] = "#{self.uri}/collections/"
      end
    end      
    relationships
  end
  
  def entry(format)
    relationships = {}
   
    {:id=>self.uri,:title=>self.title,:updated=>self.MODIFIED_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:categories=>categories,
      :content_type=>AppConfig.connector['record_types'][format]['content-type'],:relationships=>relationships}
  end

  def generate_content
    if self.RAW_DATA
      marc = MARC::ForgivingReader.new(StringIO.new(self.RAW_DATA))
      marc.each {|rec| @content = rec }
    end
  end
  
  def self.find_associations(entity_list)
    ids = []
    entities = {}
    entity_list.each do | entity |
      ids << entity.id
      entities[entity.id] = entity
    end
    Title.find_all_by_WORK_ID_and_COLLECTION_ID(ids, !nil).each do | title |
      entities[title.WORK_ID].has_collections = true
    end
  end
  
  def self.find_eager(ids)
    return self.find(ids, :include=>[:items])
  end
  
  def self.find_by_filter(filter, limit)
    if filter == 'opac'
      works = self.find_all_by_SUPPRESS_FROM_OPAC_and_SUPPRESS_FROM_INDEX('F','F', :limit=>limit, :order=>"MODIFIED_DATE desc")
    end    
    works
  end
  
  def self.count_by_filter(filter)
    if filter == 'opac'
      works = self.count(:conditions=>"SUPPRESS_FROM_OPAC = 'F' AND SUPPRESS_FROM_INDEX = 'F'")
    end    
    works
  end  
  def get_relationships(rel, offset, limit) 
    related_entities = []
    if rel == 'items'
      if self.items
        related_entities = related_entities + self.items
      end
      if self.holdings
        related_entities = related_entities + self.holdings
      end
    elsif rel == 'collections'
      related_entities = self.collections
    end
    related_entities
  end
  
  def self.cql_index_to_sql_column(index)  
    column = case index
      when "rec.identifier" then "WORK_ID"
      when "rec.lastModificationDate" then "MODIFIED_DATE"
      end
    column
  end
end
