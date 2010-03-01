class Item < AltoModel
  set_table_name 'ITEM'
  set_primary_key 'ITEM_ID'

  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  has_many :borrowers, :through=>:loans
  has_many :loans, :foreign_key=>"ITEM_ID"
  has_many :reservations, :foreign_key=>"SATISFYING_ITEM_ID"
  belongs_to :classification, :foreign_key=>"CLASS_ID"
  belongs_to :location, :foreign_key=>"ACTIVE_SITE_ID"
  has_many :ill_requests, :foreign_key=>"ITEM_ID"
  
  attr_accessor :status, :loan_type, :via
  
  def self.last_modified_field
    "EDIT_DATE"
  end
  
  def title
    case available?
    when true then "Available"
    else "Unavailable"
    end
  end

  def to_doc
    edit_date = (self.EDIT_DATE||self.CREATE_DATE||Time.now)
    edit_date.utc
    doc = {:id=>"Item_#{self.ITEM_ID}", :last_modified=>edit_date.xmlschema, :model=>self.class.to_s, :model_id=>self.ITEM_ID}
    doc[:type_id] = self.TYPE_ID
    doc[:status_id] = self.STATUS_ID    
    doc[:location_id] = self.ACTIVE_SITE_ID
    doc[:format_id] = self.FORMAT_ID
    doc
  end
  
  def identifier
    "I-#{self.id}"
  end
  
  def updated
    (self.EDIT_DATE||self.CREATE_DATE||Time.now).xmlschema
  end
  
  def daia_service
    return nil unless self.loan_type
    svc = case self.loan_type.NAME
    when 'REFERENCE' then 'presentation'
    when 'Not for Loan' then 'presentation'
    when 'INTERLOAN' then 'interloan'
    else 'loan'
    end
    svc
  end
  
  def relationships
    relationships = nil
    if self.WORK_ID
      relationships = {'http://jangle.org/vocab/Entities#Resource' => "#{self.uri}/resources/"}
    end
    relationships
  end
  
  def categories
    add_category('item')
    @categories
  end
  
  def availability_message
    message = ""
    if available?
      unless self.status
        self.status = TypeStatus.find_by_SUB_TYPE_and_TYPE_STATUS(6,self.STATUS_ID)
      end
      if !self.status.OPAC_MESSAGE.nil? and self.status.OPAC_MESSAGE != ""
        message = self.status.OPAC_MESSAGE
      else
        message = self.status.NAME
      end      
    elsif curr_loan = self.loans.find(:first, :conditions=>"CURRENT_LOAN = 'T'")
      #
      loan_type = LoanRule.find(:first, :conditions=>{:LOCATION_PROFILE_ID=>self.location.LOCATION_PROFILE_ID,
        :BORROWER_TYPE=>curr_loan.borrower.TYPE_ID, :ITEM_TYPE=>self.TYPE_ID, :LOAN_TYPE=>curr_loan.LOAN_TYPE})
      if loan_type
        message = loan_type.due_date.NAME
      else
        self.status = TypeStatus.find_by_SUB_TYPE_and_TYPE_STATUS(24,curr_loan.LOAN_TYPE)
        if !self.status.OPAC_MESSAGE.nil? and self.status.OPAC_MESSAGE != ""
          message = self.status.OPAC_MESSAGE
        else
          message = self.status.NAME
        end
      end
    end
    message
  end
  
  def entry(format)

    {:id=>self.uri,:title=>title,:updated=>self.EDIT_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end  
  
  def to_marcxml
    return marc.to_xml
  end
  
  def to_marc
    return marc.to_marc
  end
  
  def marc
    record = MARC::Record.new
    record.leader[5] = 'n'    
    record.leader[6] = 'x'
    record.leader[9] = 'a'
    record.leader[17] = '1'
    record.leader[18] = 'i'
    record << MARC::ControlField.new('001',self.identifier)
    record << MARC::ControlField.new('004',self.WORK_ID.to_s)
    record << MARC::ControlField.new('005',(self.EDIT_DATE||self.CREATE_DATE).strftime("%Y%m%d%H%M%S.0"))
    if self.classification
      scheme = case self.classification.CLASS_AREA_ID.strip
      when 'DDC' then "1"
      when 'LC' then "0"
      end
    else
      scheme = nil
    end
    location = MARC::DataField.new('852', scheme)
    unless self.ACTIVE_SITE_ID.nil? or self.ACTIVE_SITE_ID.empty?
      location.append(MARC::Subfield.new('a', self.location.NAME)) if self.location and self.location.NAME
    end
    if self.classification
      location.append(MARC::Subfield.new('h', self.classification.CLASS_NUMBER))
    end
    unless self.SUFFIX.nil? or self.SUFFIX.empty?
      location.append(MARC::Subfield.new('i', self.SUFFIX))
    end
    record << location
    item_basic = MARC::DataField.new('876')
    item_basic.append MARC::Subfield.new('a', self.id.to_s)
    item_basic.append MARC::Subfield.new('d',self.CREATE_DATE.strftime("%Y%m%d"))
    if self.availability_message
      item_basic.append MARC::Subfield.new('j',self.availability_message)
    end
    
    unless self.BARCODE.nil? or self.BARCODE.empty?
      item_basic.append MARC::Subfield.new('p',self.BARCODE)
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
    self.loans.each do | loan |
      if loan.CURRENT_LOAN == 'T'
        return false
      end
    end

    if self.status
      unless status.TYPE_STATUS == 5
        return false
      end
    end
    true
  end
  
  def date_available
    if available?
      return DateTime.now.xmlschema
    else
      if curr_loan = self.loans.find(:first, :conditions=>"CURRENT_LOAN = 'T'")
        return curr_loan.DUE_DATE.xmlschema
      end
    end
  end
  
  def self.find_eager(ids)
    return self.find(:all, :conditions=>{:ITEM_ID=>ids}, :include=>[:loans, :classification, :location])
  end  
  
  def self.find_associations(entity_list)
    status_ids = []
    loan_type_ids = []
    status_map = {}
    loan_type_map = {}
    entities = {}
    entity_list.each do | entity |
      next unless entity.is_a?(Item)
      entities[entity.id] = entity
      status_ids << entity.STATUS_ID
      status_map[entity.STATUS_ID] ||=[]
      status_map[entity.STATUS_ID] << entity
      loan_type_ids << entity.TYPE_ID
      loan_type_map[entity.TYPE_ID] ||=[]
      loan_type_map[entity.TYPE_ID] << entity
    end
    status_ids.uniq!
    loan_type_ids.uniq!
    states = TypeStatus.find_all_by_SUB_TYPE_and_TYPE_STATUS(6,status_ids)
    loan = TypeStatus.find_all_by_SUB_TYPE_and_TYPE_STATUS(1,loan_type_ids)  
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
  end 
  
  def get_relationships(rel, filter, offset, limit) 
    related_entities = []
    if rel == 'resources'
      related_entities << self.work_meta
    elsif rel == 'actors'
      if filter.nil? or filter == 'loan'
        self.loans.find_all_by_CURRENT_LOAN('T').each do | loan |
          loan.borrower.add_category('loan')
          related_entities << loan.borrower
        end
      end
      if filter.nil? or filter == 'hold'
        self.reservations.find(:all, :conditions=>"STATE < 5").each do | rsv |
          rsv.borrower.add_category('hold')
          related_entities << rsv.borrower
        end
      end
      if filter.nil? or filter == 'interloan'
        self.ill_requests.find(:all, :conditions=>"ILL_STATUS < 6").each do | ill |
          ill.borrower.add_category('interloan')
          related_entities << ill.borrower
        end      
      end
    end
    related_entities.each do | rel |
      rel.via = self
    end    
    related_entities
  end
  
  def charges(borrower_id)
    charges = {}
    self.loans.find_all_by_BORROWER_ID(borrower_id).each do | loan |
      if loan.CURRENT_LOAN == "F"
        loan_charges = loan.fines
        if loan_charges > 0.00
          charges[:loans] = loan_charges
        end
      else
        due_date = loan.DUE_DATE.strftime("%m/%d/%Y %H:%M:%S")
        calc_fine_sp = self.connection.exec_stored_procedure("exec CL_CALC_FINE_SP #{loan.LOAN_TYPE}, '#{due_date}', '#{loan.CREATE_LOCATION}', #{loan.borrower.TYPE_ID}, #{loan.item.TYPE_ID}")
        if calc_fine_sp.first.values.first.to_f > 0.00
          charges[:loans] = calc_fine_sp.first.values.first.to_f
        end
      end
    end
    charges
  end

  def set_uri(base, path)
    @uri = "#{base}/#{path}/#{identifier}"
  end   
end
