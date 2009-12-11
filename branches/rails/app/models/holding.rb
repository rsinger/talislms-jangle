class Holding < AltoModel
  set_table_name 'SITE_SERIAL_HOLDINGS'
  set_primary_key 'HOLDINGS_ID'
  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  belongs_to :classification, :foreign_key=>"CLASS_ID"
  belongs_to :location, :foreign_key=>"LOCATION_ID"
  attr_accessor :harvest_item
  def title 
    (1..4).each do | holdings_note |
      note = self.send("HOLDINGS#{holdings_note}")
      return note unless note.nil? or note.empty?
    end
    "Holdings not available"
  end
  
  def to_doc
    if self.work_meta && self.work_meta.MODIFIED_DATE
      edit_date = self.work_meta.MODIFIED_DATE
    else
      edit_date = Time.now
    end
    edit_date.utc
    doc = {:id=>"Holding_#{self.HOLDINGS_ID}", :last_modified=>edit_date.xmlschema, :model=>self.class.to_s, :model_id=>self.HOLDINGS_ID}
    doc[:location_id] = self.LOCATION_ID
    doc
  end
    
  def daia_service
    'presentation'
  end
  
  def identifier
    "H-#{self.id}"
  end
  
  def updated
    if self.work_meta && self.work_meta.MODIFIED_DATE
      u = self.work_meta.MODIFIED_DATE
    else
     u = Time.now
   end
   u.xmlschema
  end
  
  def relationships
    relationships = nil
    if self.work_meta
      relationships = {'http://jangle.org/vocab/Entities#Resource' => "#{self.uri}/resources/"}
    end
  end  
  
  def categories
    add_category('holding')
    @categories
  end
  
  def to_marcxml
    return marc.to_xml
  end
  
  def to_marc
    marc.to_marc
  end
  
  def marc

    record = MARC::Record.new
    record.leader[5] = 'n'    
    record.leader[6] = 'y'
    record.leader[9] = 'a'
    record.leader[17] = '3'
    record.leader[18] = 'i'
    record << MARC::ControlField.new('001',self.identifier)
    record << MARC::ControlField.new('004',self.WORK_ID.to_s)
    if self.work_meta && self.work_meta.MODIFIED_DATE
      record << MARC::ControlField.new('005',self.work_meta.MODIFIED_DATE.strftime("%Y%m%d%H%M%S.0"))
    end
    scheme = case self.classification.CLASS_AREA_ID.strip
    when 'DDC' then "1"
    when 'LC' then "0"
    end
    location = MARC::DataField.new('852', scheme)
    unless self.LOCATION_ID.nil? or self.LOCATION_ID.empty?
      location.append(MARC::Subfield.new('a', self.location.NAME))
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
  
  def self.find_associations(entity_list)
 
  end
  def self.find_eager(ids)
    return self.find(:all, :conditions=>{:HOLDINGS_ID=>ids}, :include=>[:work_meta, :classification, :location])
  end  
  
  def set_uri(base, path)
    @uri = "#{base}/#{path}/#{self.harvest_item.id}"
  end  
  
  def self.sync_from(timestamp)
    while rows = Holding.find_by_sql(["SELECT TOP 1000 h.*, w.MODIFIED_DATE FROM SITE_SERIAL_HOLDINGS h, WORKS_META w WHERE h.WORK_ID = w.WORK_ID AND w.MODIFIED_DATE >= ? ORDER BY w.MODIFIED_DATE", timestamp])
      break if rows.empty?
      puts "Updating #{self.to_s} from timestamp: #{timestamp}"
      docs = []
      rows.each {|row| docs << row.to_doc }
      docs.each {|doc| AppConfig.solr.add(doc)}
      timestamp = rows.last.work_meta.MODIFIED_DATE unless rows.empty?
      AppConfig.solr.commit
      results = AppConfig.solr.select :q=>"model:#{docs.last[:model]}"
      puts "#{results["response"]["numFound"]} #{docs.last[:model]} documents in Solr index"
      break if rows.empty? or rows.length == 1
    end    
    AppConfig.solr.commit    
  end  
  
  def get_relationships(rel, offset, limit) 
    related_entities = []
    if rel == 'resources'
      related_entities << self.work_meta
    end
    related_entities
  end  
end
