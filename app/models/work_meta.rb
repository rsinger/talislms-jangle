class WorkMeta < AltoModel
  # TODO: Should Work be the representative model for resources?
  set_table_name 'WORKS_META'
  set_primary_key 'WORK_ID'
  has_many :items, :foreign_key=>"WORK_ID"
  has_many :titles, :foreign_key=>"WORK_ID"
  has_many :collections, :through=>:titles
  has_many :holdings, :foreign_key=>"WORK_ID"
  has_one :work, :foreign_key=>"WORK_ID"
  attr_accessor :has_collections, :via, :current_reservations
  alias :identifier :id
  
  # Returns the total count of rows by requested category
  def self.count_by_filter(filter)
    if filter == 'opac'
      works = self.count(:conditions=>"SUPPRESS_FROM_OPAC = 'F' AND SUPPRESS_FROM_INDEX = 'F'")
    end    
    works
  end  
  
  # Maps the incoming CQL query index to the corresponding SQL column
  def self.cql_index_to_sql_column(index)  
    column = case index
      when "rec.identifier" then "WORK_ID"
      when "rec.lastModificationDate" then "MODIFIED_DATE"
      end
    column
  end
    
  # Find the related objects and associate them.
  # TODO: this needs to be broken up and moved into WorkMeta.post_hooks
  # to be more efficient.  Also, make the association to Items or Holdings here, maybe.
  def self.find_associations(entity_list)
  end

  # Find WorkMeta rows based on the requested category
  def self.find_by_filter(filter, limit)
    if filter == 'opac'
      works = self.find_all_by_SUPPRESS_FROM_OPAC_and_SUPPRESS_FROM_INDEX('F','F', :limit=>limit, :order=>"MODIFIED_DATE desc")
    end    
    works
  end
  
  # When initializing WorkMeta objects be sure they already have the necessary associated items.
  # TODO: Items should probably be put in a post_hook call, since this doesn't grab Holdings.  
  def self.find_eager(ids)
    return self.find(:all, :conditions=>{:WORK_ID=>ids}, :include=>[:work])
  end
  
  # WORK_META.MODIFIED_DATE is WorkMeta's last-modified column
  def self.last_modified_field
    "MODIFIED_DATE"
  end

  # Return the first 'page' of works.  If offset is greater than zero, uses WorkMetaCache instead.
  def self.page(offset, limit)
    if offset > 0
      return WorkMetaCache.page(offset, limit)
    end
    result_set =  ResultSet.new(self.all(:limit=>limit, :order=>"#{self.last_modified_field} DESC", :include=>[:work]))
    result_set.total_results = self.count
    result_set
  end  
  
  def self.post_hooks(entities, format, params)
    works = {}
    entities.each do | e |
      next unless e.is_a?(WorkMeta)
      works[e.id] = e
    end
    if format == "alto"
      # Make all the TypeStatus requests for the Work objects
      type_status = {:status=>[], :work_type=>[], :contribution_type=>[], :ibm_status=>[]}
      entities.each do |e|
        next unless e.work
        if e.work.STATUS
          type_status[:status] << e.work.STATUS
        end
        if e.work.TYPE_OF_WORK
          type_status[:work_type] << e.work.TYPE_OF_WORK
        end
        if e.work.CONTRIBUTION_TYPE
          type_status[:contribution_type] << e.work.CONTRIBUTION_TYPE
        end
        if e.work.IBM_STATUS
          type_status[:ibm_status] << e.work.IBM_STATUS
        end
      end
      type_status.each_pair do | k, v|
        v.uniq!
      end
      conditions = []
      args = []
      unless type_status[:status].empty?
        conditions << "(TYPE_STATUS IN (?) AND SUB_TYPE = 5)"
        args << type_status[:status]
      end
      unless type_status[:work_type].empty?
        conditions << "(TYPE_STATUS IN (?) AND SUB_TYPE = 0)"
        args << type_status[:work_type]
      end      
      unless type_status[:contribution_type].empty?
        conditions << "(TYPE_STATUS IN (?) AND SUB_TYPE = 19)"
        args << type_status[:contribution_type]
      end
      unless type_status[:ibm_status].empty?
        conditions << "(TYPE_STATUS IN (?) AND SUB_TYPE = 15)"
        args << type_status[:ibm_status]
      end  
      stmt = [conditions.join(" OR ")] + args
      status = {:status=>{},:work_type=>{}, :contribution_type=>{}, :ibm_status=>{}}
      TypeStatus.find(:all, :conditions=>stmt).each do |ts|    
        case ts.SUB_TYPE
        when 5
          status[:status][ts.TYPE_STATUS] = ts
        when 0
          status[:work_type][ts.TYPE_STATUS] = ts
        when 19
          status[:contribution_type][ts.TYPE_STATUS] = ts
        when 15
          status[:ibm_status][ts.TYPE_STATUS] = ts
        end
      end
      entities.each do | e |
        next unless e.work
        e.work.status = status[:status][e.work.STATUS]
        e.work.work_type = status[:work_type][e.work.TYPE_OF_WORK]
        e.work.contribution_type = status[:contribution_type][e.work.CONTRIBUTION_TYPE]
        e.work.ibm_status = status[:ibm_status][e.work.IBM_STATUS]
      end
    end
    Title.find_by_sql(["SELECT DISTINCT WORK_ID FROM TITLE WHERE WORK_ID IN (?) AND COLLECTION_ID IS NOT NULL", works.keys]).each do |title|
      works[title.WORK_ID].add_relationship('collection')
    end
    Item.find_by_sql(["SELECT DISTINCT WORK_ID FROM ITEM WHERE WORK_ID IN (?)", works.keys]).each do |item|
      works[item.WORK_ID].add_relationship('item')
    end
    Holding.find_by_sql(["SELECT DISTINCT WORK_ID FROM SITE_SERIAL_HOLDINGS WHERE WORK_ID IN (?)", works.keys]).each do |holding|
      works[holding.WORK_ID].add_relationship('item')
    end    
    Reservation.find(:all, :conditions=>["RESERVATION.STATE < 5 AND RESERVED_LINK.TYPE = 1 AND RESERVED_LINK.TARGET_ID IN (?)", works.keys],
    :joins => "LEFT JOIN RESERVED_LINK ON RESERVATION.RESERVATION_ID = RESERVED_LINK.RESERVATION_ID",
    :select => "RESERVATION.*, RESERVED_LINK.TARGET_ID as work_id").each do |rsv|
      works[rsv.attributes['work_id']].current_reservations ||=[]
      works[rsv.attributes['work_id']].current_reservations << rsv
    end    
  end

  # Returns an Array of the categories set for the WorkMeta object.  To be in the 'opac'
  # (aka 'discovery interface') category, both SUPPRESS_FROM_OPAC and SUPPRESS_FROM_INDEX
  # must be false.
  def categories
    unless self.SUPPRESS_FROM_OPAC == 'T' or self.SUPPRESS_FROM_INDEX == 'T'
      add_category('opac')
    end
    @categories
  end
  
  # Returns the Jangle entry.
  # TODO: this needs to be deprecated into a view.  
  def entry(format)
    relationships = {}
    {:id=>self.uri,:title=>self.title,:updated=>self.MODIFIED_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:categories=>categories,
      :content_type=>AppConfig.connector['record_types'][format]['content-type'],:relationships=>relationships}
  end  
  
  def self.get_relationships(ids, rel, filter, offset, limit)
    related_entities = []
    if rel == 'items'

      items = Item.find(:all, :conditions=>["WORK_ID IN (?)", [*ids]], :select=>"ITEM_ID, WORK_ID", :include=>[:work_meta], :offset=>offset, :limit=>limit)
      i = {}
      items.each do |item|
        i["I-#{item.id}"] ||=[]
        i["I-#{item.id}"] << item.work_meta
      end
       
      holdings = Holding.find(:all, :conditions=>["WORK_ID IN (?)", [*ids]], :select=>"HOLDINGS_ID, WORK_ID", :include=>[:work_meta], :offset=>offset, :limit=>limit)
      holdings.each do |holding|
        i["H-#{holding.id}"] ||=[]

        i["H-#{holding.id}"] << holding.work_meta
      end      

      ItemHoldingCache.find(i.keys).each do | item |      
        next if filter && !item.categories.index(filter)
        i[item.identifier].each do |work|
          item.via ||=[]
          item.via << work
        end
        related_entities << item 
      end

    elsif rel == 'collections'
      #related_entities = self.collections
      titles = Title.find(:all, :conditions=>["WORK_ID IN (?)", [*ids]], :include=>[:work_meta, :collection], :offset=>offset, :limit=>limit)
      collections = {}
      titles.each do |title|
        unless collections[title.collection.id]
          collections[title.collection.id] = title.collection
          collections[title.collection.id].via = []
        end
        collections[title.collection.id].via << title.work_meta
      end
      related_entities = collections.values
    end
 
    related_entities 
  end
  
  # Gets the related entities to the WorkMeta object and sets appropriate categories
  # TODO: this should become a class method, since we don't actually *need*
  # the WorkMetas themselves to accomplish this (and would be more efficient)  
  def get_relationships(rel, filter, offset, limit) 
    related_entities = []
    if rel == 'items'

      items = Item.find(:all, :conditions=>["WORK_ID = ?", self.WORK_ID], :include=>[:work_meta, :classification, :location, :work], :offset=>offset, :limit=>limit)
      i = {}
      items.each do |item|
        i[item.id] = item
      end
      Loan.find_all_by_ITEM_ID_and_CURRENT_LOAN(i.keys, "T").each do |loan|
        i[loan.ITEM_ID].current_loans ||=[]
        i[loan.ITEM_ID].current_loans << loan
        i[loan.ITEM_ID].add_relationship('actor')
      end          
      
      items.each do | item |      
        next if filter && !item.categories.index(filter)
        related_entities << item 
      end
      if self.holdings
        related_entities = related_entities + self.holdings[offset, limit]
      end
    elsif rel == 'collections'
      related_entities = self.collections
    end
    related_entities.each do | rel |
      rel.via = self
    end    
    related_entities
  end  
     
  # Return the title for the feed entry
  # TODO: this is currently *REALLY* inefficient.  It might be more practical to JOIN WORK_META to WORKS
  # from the start and pull from there or make the coupling with WorkMetaCache (which has already
  # generated a title) more seamless.
  def title
    title = nil
    if self.work && self.work.TITLE_DISPLAY
      return self.work  .TITLE_DISPLAY.sub(/^\. \-\s*/,'')
    elsif self.RAW_DATA
      begin
        marc = MARC::Record.new_from_marc(self.RAW_DATA)
        if marc['245'] && marc['245']['a']
          return marc['245']['a']
        end
      rescue
      end
    end
    "Title not available"
  end
  
  # Returns a MARCXML record.  Send an XSLT to get RDF/DC
  def to_dc
    to_marcxml
  end
    
  # Returns a Hash to store in Solr
  def to_doc
    edit_date = (self.MODIFIED_DATE||Time.now)
    edit_date.utc
    doc = {:id=>"WorkMeta_#{self.WORK_ID}", :last_modified=>edit_date.xmlschema, :model=>self.class.to_s, :model_id=>self.WORK_ID}
    doc[:category] = self.categories
    doc[:title] = self.title.gsub(/\020/,'')
    doc
  end  
  
  # Returns a binary (ISO 27709) MARC record
  def to_marc
    self.RAW_DATA
  end
  
  # Returns a MARCXML record
  def to_marcxml    
    begin
      MARC::Record.new_from_marc(self.RAW_DATA).to_xml if self.RAW_DATA
    rescue
      ""
    end
  end

  # Returns a MARCXML record.  Send an XSLT to get MODS
  def to_mods
    to_marcxml
  end

  # Returns a MARCXML record.  Send an XSLT to get OAI-DC
  def to_oai_dc
    to_marcxml
  end 
  
  # Returns the last-modified Timestamp or the current time (if the value is not set)
  def updated
    (self.MODIFIED_DATE||Time.now)
  end  
end
