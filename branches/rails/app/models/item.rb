class Item < AltoModel
  set_table_name 'ITEM'
  set_primary_key 'ITEM_ID'

  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  has_many :borrowers, :through=>:loans
  has_many :loans, :foreign_key=>"ITEM_ID"
  belongs_to :classification, :foreign_key=>"CLASS_ID"
  belongs_to :location, :foreign_key=>"ACTIVE_SITE_ID"
  
  attr_accessor :status, :loan_type, :harvest_item
  
  def title
    case available?
    when true then "Available"
    else "Unavailable"
    end
  end
  
  def updated
    self.EDIT_DATE.xmlschema
  end
  
  def relationships
    relationships = nil
    if self.WORK_ID
      relationships = {'http://jangle.org/rel/related#Resource' => "#{self.harvest_item.id}/resources/"}
    end
    relationships
  end
  
  def categories
    ['item']
  end
  
  def availability_message
    unless self.status
      self.status = TypeStatus.find_by_SUB_TYPE_and_TYPE_STATUS(6,self.STATUS_ID)
    end
    self.status.NAME
  end
  
  def entry(format)

    {:id=>self.uri,:title=>self.NAME,:updated=>self.EDIT_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end  
  
  def to_marcxml
    return marc.to_xml
  end
  
  def marc
    unless self.harvest_item
      self.harvest_item =  HarvestItem.find_by_item_id(self.id)
    end
    record = MARC::Record.new
    record.leader[5] = 'n'    
    record.leader[6] = 'x'
    record.leader[9] = 'a'
    record.leader[17] = '1'
    record.leader[18] = 'i'
    record << MARC::ControlField.new('001',self.harvest_item.id.to_s)
    record << MARC::ControlField.new('004',self.WORK_ID.to_s)
    record << MARC::ControlField.new('005',self.EDIT_DATE.strftime("%Y%m%d%H%M%S.0"))
    scheme = case self.classification.CLASS_AREA_ID.strip
    when 'DDC' then "1"
    when 'LC' then "0"
    end
    location = MARC::DataField.new('852', scheme)
    unless self.ACTIVE_SITE_ID.nil? or self.ACTIVE_SITE_ID.empty?
      location.append(MARC::Subfield.new('a', self.location.NAME))
    end
    if self.classification
      location.append(MARC::Subfield.new('h', self.classification.CLASS_NUMBER))
    end
    if self.SUFFIX
      location.append(MARC::Subfield.new('i', self.SUFFIX))
    end
    record << location
    item_basic = MARC::DataField.new('876')
    item_basic.append MARC::Subfield.new('a', self.id.to_s)
    item_basic.append MARC::Subfield.new('d',self.CREATE_DATE.strftime("%Y%m%d"))
    if self.availability_message
      item_basic.append MARC::Subfield.new('j',self.availability_message)
    end
    unless self.DESC_NOTE.nil? or self.DESC_NOTE.empty?
      item_basic.append MARC::Subfield.new('z',self.DESC_NOTE)
    end
    unless self.CONTENT_NOTE.nil? or self.CONTENT_NOTE.empty?
      item_basic.append MARC::Subfield.new('3',self.CONTENT_NOTE)
    end
    record << item_basic
    record
    
  end
  
  def available?
    loans = self.loans.find_by_CURRENT_LOAN('Y')
    if loans
      return false
    end
    if self.status
      unless status.TYPE_STATUS == 5
        return false
      end
    end
    true
  end
  
  def self.find_eager(ids)
    return self.find(ids, :include=>[:loans, :classification, :location])
  end  
  
  def self.find_associations(entity_list)
    status_ids = []
    loan_type_ids = []
    status_map = {}
    loan_type_map = {}
    entities = {}
    entity_list.each do | entity |
      entities[entity.id] = entity
      status_ids << entity.STATUS_ID
      status_map[entity.STATUS_ID] ||=[]
      status_map[entity.STATUS_ID] << entity
      loan_type_ids << entity.TYPE_ID
      loan_type_map[entity.TYPE_ID] ||=[]
      loan_type_map[entity.TYPE_ID] << entity
    end
    status_ids.uniq!
    item_type_ids.uniq!
    states = TypeStatus.find_all_by_SUB_TYPE_AND_TYPE_STATUS(6,status_ids)
    loan = TypeStatus.find_all_by_SUB_TYPE_AND_TYPE_STATUS(1,loan_type_ids)  
    harvest_items = HarvestItem.find_by_item_id(entities.keys)  
    states.each do | state |
      status_map[state.TYPE_STATUS].each do | entity |
        entity.status = state
      end
    end
    loan.each do | l |
      loan_type_map[l.TYPE_STATUS].each do | entity |
        entity.loan_type = l
      end
    end
    harvest_items.each do | hi |
      entities[hi.item_id].harvest_item = hi
    end
  end  

end
