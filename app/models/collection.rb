class Collection < AltoModel
  set_table_name 'COLLECTION'
  set_primary_key 'COLLECTION_ID'
  has_many :titles, :foreign_key=>'COLLECTION_ID'
  has_many :work_metas, :through=>:titles
  attr_accessor :has_works, :via
  alias :identifier :id
  
  # Associates the related entities to a single Collection or array of Collections
  # Currently disabled and assumes that a Collection has Resources related to it
  # due to a missing index relating WORKS and COLLECTION (on the TITLE table)
  def self.find_associations(entity_list)
    [*entity_list].each do |e|
      e.has_works = true
    end
    #ids = []
    #entities = {}
    #entity_list.each do | entity |
    #  ids << entity.id
    #  entities[entity.id] = entity
    #end
    
    # It appears an index is missing for COLLECTION_ID on TITLE since this query is 
    # painfully slow.
    #Title.find_by_sql(["SELECT DISTINCT COLLECTION_ID FROM TITLE WHERE COLLECTION_ID IN (?) AND WORK_ID IS NOT NULL", ids]).each do | title |
    #  entities[title.COLLECTION_ID].has_works = true
    #end
  end  
  
  # Find all collections by category
  # TODO: actually advertise the categories
  def self.find_by_filter(filter, opts={})
    opts[:offset] ||=0
    opts[:limit] ||= AppConfig.connector['page_size']
    if filter == 'ill'
      collections = ResultSet.new(self.find_all_by_INTERLOANS('T',:limit=>opts[:limit], :offset=>opts[:offset]))
      collections.total_results = self.count_by_INTERLOANS('T')
    end
    collections
  end
  
  # Returns the first page of Collections.  It is assumed there will not be more than
  # 100 collections defined, but if there are, there will need to be a CollectionCache
  # created and refactored to use Solr.
  def self.page(offset, limit)
    result_set =  ResultSet.new(self.all(:limit=>limit))
    result_set.total_results = self.count
    result_set
  end  
  
  # Collections have no created timestamp available
  def created
    nil
  end  
  
  # Serialize the Collection as Dublin Core  
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
  
  # Returns the Jangle entry.
  # TODO: this needs to be deprecated into a view.  
  def entry(format)  
    {:id=>self.uri,:title=>self.NAME,:updated=>updated,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end  
  
  def self.get_relationships(ids, rel, filter, offset, limit)
    related_entities = []
    if rel == 'resources'
      titles = Title.find(:all, :conditions=>["COLLECTION_ID IN (?)", [*ids]], :include=>[:work_meta, :collection], :offset=>offset, :limit=>limit)
      works = {}
      titles.each do |title|
        unless works[title.work_meta.id]
          works[title.work_meta.id] = title.work_meta
          works[title.work_meta.id].via = []
        end
        works[title.work_meta.id].via << title.collection
      end
      related_entities = works.values
    end
  end
  
  # Gets the related Resources associated with a Collection
  # TODO: this almost certainly doesn't work right.  It probably
  # makes more sense to include the Collections in WorkMeta.to_doc and
  # retrieve them via WorkMetaCache
  def get_relationships(rel, filter, offset, limit) 
    related_entities = []
    if rel == 'resources'
      related_entities = self.work_metas.find(:all, :limit=>limit, :offset=>offset)
    end
    related_entities.each do | rel |
      rel.via = self
    end    
    related_entities
  end  
  
  # Convenience method to normalize Sybase's (or Alto's?) booleans to actual Booleans
  def interloan?
    if self.INTERLOANS == "T"
      true
    else
      false
    end
  end

  # Return a "title" for feed responses
  def title
    self.NAME
  end  
  
  # Collections have no timestamps whatsoever, but Jangle (via Atom) request a last-modified
  # value.  We're just returning the current timestamp, always.
  # TODO: set this to something that won't break caching on every request
  def updated
    Time.now
  end

end
