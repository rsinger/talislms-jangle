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
      w = Work.find(self.WORK_ID)
      if w
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
    MARC::Record.new_from_marc(self.RAW_DATA).to_marc
  end
  
  def to_marcxml
    MARC::Record.new_from_marc(self.RAW_DATA).to_xml
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
    self.MODIFIED_DATE.xmlschema
  end
  
  def relationships
    relationships = nil
    if self.items or self.has_collections
      relationships = {}
      if self.items
        relationships['http://jangle.org/rel/related#Item'] = "#{self.uri}/items/"
      end
      if self.has_collections
        relationships['http://jangle.org/rel/related#Collection'] = "#{self.uri}/collections/"
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
      puts limit
      works = self.find_all_by_SUPPRESS_FROM_OPAC_and_SUPPRESS_FROM_INDEX('F','F', :limit=>limit, :order=>"MODIFIED_DATE desc")
    end    
    works
  end
end
