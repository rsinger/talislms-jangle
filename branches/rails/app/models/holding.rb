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
  
  def daia_service
    'presentation'
  end
  
  def identifier
    unless self.harvest_item
      self.harvest_item =  HarvestItem.find_by_holding_id(self.id)
    end    
    self.harvest_item.id
  end
  
  def updated
    self.work_meta.MODIFIED_DATE.xmlschema
  end
  
  def relationships
    relationships = nil
    if self.WORK_ID
      relationships = {'http://jangle.org/rel/related#Resources' => "#{self.id}/resources/"}
    end
  end  
  
  def categories
    ['holding']
  end
  
  def to_marcxml
    return marc.to_xml
  end
  
  def to_marc
    marc.to_marc
  end
  
  def marc
    unless self.harvest_item
      self.harvest_item =  HarvestItem.find_by_holding_id(self.id)
    end
    record = MARC::Record.new
    record.leader[5] = 'n'    
    record.leader[6] = 'y'
    record.leader[9] = 'a'
    record.leader[17] = '3'
    record.leader[18] = 'i'
    record << MARC::ControlField.new('001',self.harvest_item.id.to_s)
    record << MARC::ControlField.new('004',self.WORK_ID.to_s)
    record << MARC::ControlField.new('005',self.work_meta.MODIFIED_DATE.strftime("%Y%m%d%H%M%S.0"))
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
    entities = {}
    entity_list.each do | entity |
      next unless entity.is_a?(Holding)
      entities[entity.id] = entity 
    end   
    harvest_items = HarvestItem.find_all_by_holding_id(entities.keys)  
    harvest_items.each do | hi |
      entities[hi.holding_id].harvest_item = hi
    end    
  end
  def self.find_eager(ids)
    return self.find(ids, :include=>[:work_meta, :classification, :location])
  end  
end
