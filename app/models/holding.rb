class Holding < AltoModel
  set_table_name 'SITE_SERIAL_HOLDINGS'
  set_primary_key 'HOLDINGS_ID'
  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  belongs_to :classification, :foreign_key=>"CLASS_ID"
  belongs_to :location, :foreign_key=>"LOCATION_ID"
  belongs_to :work, :foreign_key=>"WORK_ID"
  attr_accessor :via
  
  # Class methods
  
  # Nothing is currently associated with holdings, but we need the stub, anyway.
  # TODO:  move this AltoModel
  def self.find_associations(entity_list);end
  
  # When retrieving Holdings, we need to JOIN on WORKS since that is the source
  # of the last-modified attribute (SITE_SERIAL_HOLDINGS) has no timestamps.
  # While, we're at it, get the Classification and Location of the holdings.
  def self.find_eager(ids)
    holdings = self.find(:all, :conditions=>{:HOLDINGS_ID=>ids}, :include=>[:work, :classification, :location],
    :joins => "LEFT JOIN WORKS ON SITE_SERIAL_HOLDINGS.WORK_ID=WORKS.WORK_ID",
    :select => "SITE_SERIAL_HOLDINGS.*, WORKS.EDIT_DATE as last_modified")
    # In order to know that there's still not a timestamp even though we've JOINed to WORKS, set
    # .attributes['last_modified'] to something that's not nil
    holdings.each do | h |
      h.attributes['last_modified'] = false unless h.attributes['last_modified']
    end
    holdings
  end
  
  def self.post_hooks(entities, format, params)
    entities.each do |holding|
      holding.add_relationship('resource') unless holding.attributes['last_modified'].is_a?(FalseClass)
    end
  end      
    
  
  # Because of SITE_SERIAL_HOLDINGS' lack of any last-modified timestamps,
  # Holding needs its own .sync_from method.
  def self.sync_from(timestamp)
    while rows = Holding.find_by_sql(["SELECT TOP 1000 h.*, w.EDIT_DATE as last_modified FROM SITE_SERIAL_HOLDINGS h, WORKS w WHERE h.WORK_ID = w.WORK_ID AND w.EDIT_DATE >= ? ORDER BY w.EDIT_DATE", timestamp])
      break if rows.empty? or (rows.length == 1 && rows.first.updated == timestamp)
      RAILS_DEFAULT_LOGGER.info "Updating #{self.to_s} from timestamp: #{timestamp}"
      docs = []
      rows.each {|row| 
        row.attributes['last_modified'] = false unless row.attributes['last_modified']
        docs << row.to_doc 
      }
      AppConfig.solr.add docs
      timestamp = rows.last.updated unless rows.empty?
      AppConfig.solr.commit
      results = AppConfig.solr.select :q=>"model:#{docs.last[:model]}"
      RAILS_DEFAULT_LOGGER.info "#{results["response"]["numFound"]} #{docs.last[:model]} documents in Solr index"
      break if rows.empty? or rows.length == 1 or rows.length < 1000
    end    
    AppConfig.solr.commit    
  end  
  
  # Instance methods
    
  # Holdings should always have the category 'holding' to distinguish them
  # from copies (Items)
  def categories
    add_category('holding')
    @categories
  end  
  
  # Holdings are hard coded to 'presentation'
  def daia_service
    'presentation'
  end

  # Gets the related entities (WorkMeta) to the Holding
  # TODO: this should become a class method, since we don't actually *need*
  # the Holdings themselves to accomplish this (and would be more efficient)  
  def get_relationships(rel, filter, offset, limit) 
    related_entities = []
    if rel == 'resources'
      related_entities << self.work_meta
    end
    related_entities.each do | rel |
      rel.via = self
    end    
    related_entities
  end  
  
  # Because Holdings and Items are merged as Jangle 'items', we need to disambiguate the
  # PK with which table it came from (for Holdings, use 'H-')
  def identifier
    "H-#{self.id}"
  end  
  
  # Builds a MARC Format for Holdings Display (MFHD) record based on the summary holdings statements
  def marc
    record = MARC::Record.new
    record.leader[5] = 'n'    
    record.leader[6] = 'y'
    record.leader[9] = 'a'
    record.leader[17] = '3'
    record.leader[18] = 'i'
    record << MARC::ControlField.new('001',self.identifier)
    record << MARC::ControlField.new('004',self.WORK_ID.to_s)
    if self.attributes['last_modified']
      record << MARC::ControlField.new('005',Time.parse(updated).strftime("%Y%m%d%H%M%S.0"))
    end
    if self.classification
      scheme = case self.classification.CLASS_AREA_ID.strip
      when 'DDC' then "1"
      when 'LC' then "0"
      end
    else
      scheme = nil
    end    

    location = MARC::DataField.new('852', scheme)
    unless self.LOCATION_ID.nil? or self.LOCATION_ID.empty?
      location.append(MARC::Subfield.new('a', self.location.NAME)) if self.location and self.location.NAME
    end
    if self.classification
      location.append(MARC::Subfield.new('h', self.classification.CLASS_NUMBER))
    end
    unless self.SUFFIX.nil? or self.SUFFIX.empty?
      location.append(MARC::Subfield.new('i', self.SUFFIX))
    end
    record << location
    (1..4).each do | num |
      note = self.send("HOLDINGS#{num}")
      next if note.nil? or note.empty?
      text_holdings = MARC::DataField.new('866', '3', '0')
      text_holdings.append MARC::Subfield.new('a', note)
      want_note = self.send("WANTS_NOTE#{num}")
      unless want_note.nil? or want_note.empty?
        text_holdings.append MARC::Subfield.new('x', want_note)
      end
      gen_note = self.send("GENERAL_NOTE#{num}")
      unless gen_note.nil? or gen_note.empty?
        text_holdings.append MARC::Subfield.new('z', gen_note)
      end
      record << text_holdings
    end
    item_basic = MARC::DataField.new('876')
    item_basic.append MARC::Subfield.new('a', self.id.to_s)
    
    (1..4).each do | num |
      note = self.send("DESCRIPTIVE_NOTE#{num}")
      next if note.nil? or note.empty?
      item_basic.append MARC::Subfield.new('z',note)
    end
    record << item_basic
    record
  end  
  
  
  # Return a "title" for feed responses.  Loop through the holdings notes until something is 
  # found or return a canned message.
  def title 
    (1..4).each do | holdings_note |
      note = self.send("HOLDINGS#{holdings_note}")
      return note unless note.nil? or note.empty?
    end
    "Holdings not available"
  end  
  
  # Return a Hash to store in Solr.  Note that we include the LOCATION_ID in case we ever want to 
  # include categories defined by location.
  def to_doc
    doc = {:id=>"Holding_#{self.HOLDINGS_ID}", :last_modified=>updated.xmlschema, :model=>self.class.to_s, :model_id=>self.HOLDINGS_ID}
    doc[:location_id] = self.LOCATION_ID
    doc
  end

  # Returns a binary (ISO 27709) MARC Format for Holdings Display (MFHD) record
  def to_marc
    marc.to_marc
  end
  
  # Returns a MARCXML MFHD record  
  def to_marcxml
    marc.to_xml
  end
    
  # Because SITE_SERIAL_HOLDINGS has no last-modified timestamp column, this should have been set 
  # when initialized.
  def updated
    if self.attributes['last_modified'] && !self.attributes['last_modified'].nil? && !self.attributes['last_modified'].empty?
      edit_date = self.attributes['last_modified']
    elsif self.attributes['last_modified'].is_a?(FalseClass)
      edit_date = Time.now
    else
      if w = self.work
        edit_date = w.EDIT_DATE
      else
        edit_date = Time.now
      end
    end
    edit_date = Time.now unless edit_date
    # Not sure why this is sometimes a String rather than a Time
    edit_date = Time.parse(edit_date) if edit_date.is_a?(String)
    edit_date.utc    
    edit_date
  end 
end
