class Collection < AltoModel
  set_table_name 'COLLECTION'
  set_primary_key 'COLLECTION_ID'
  has_many :titles, :foreign_key=>'COLLECTION_ID'
  has_many :work_metas, :through=>:titles
  attr_accessor :has_works
  alias :identifier :id
  def dc
    xml = Builder::XmlMarkup.new
    xml.rdf :RDF, {"xmlns:rdf"=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'} do | rdf |
      rdf.rdf :Description, {"xmlns:dc"=>'http://purl.org/dc/elements/1.1/', 'rdf:about'=>self.uri} do | desc |
        desc.dc :title, self.NAME
        desc.dc :identifier, self.uri
        desc.rdf :type,{"rdf:resource" => "http://purl.org/dc/dcmitype/Collection"}
      end
    end
    xml.target!
  end
  
  def title
    self.NAME
  end
  
  def updated
    DateTime.now
  end
  
  def relationships
    relationships = nil
    if self.has_works
      relationships = {'http://jangle.org/vocab/Entities#Resource' => "/resources/"}
    end
    relationships
  end
  def entry(format)
    relationships = {}
  
    {:id=>self.uri,:title=>self.NAME,:updated=>DateTime.now,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end
    
  def self.find_associations(entity_list)
    ids = []
    entities = {}
    entity_list.each do | entity |
      ids << entity.id
      entities[entity.id] = entity
    end
    Title.find_by_sql(["SELECT DISTINCT COLLECTION_ID FROM TITLE WHERE COLLECTION_ID IN (?) AND WORK_ID IS NOT NULL", ids]).each do | title |
      entities[title.COLLECTION_ID].has_works = true
    end
  end  
  
  def self.find_by_filter(filter, limit, offset=0)
    if filter == 'ill'
      collections = self.find_all_by_INTERLOANS('T',:limit=>limit, :offset=>offset)
    end
    collections
  end  
  def get_relationships(rel, offset, limit) 
    related_entities = []
    if rel == 'resources'
      related_entities = self.work_metas.find(:all, :limit=>limit, :offset=>offset)
    end
    related_entities
  end  
end
