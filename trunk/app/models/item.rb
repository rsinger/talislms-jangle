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
  belongs_to :work, :foreign_key=>"WORK_ID"
  
  attr_accessor :status, :loan_type, :via, :current_loans, :item_type, :item_status
  
  # Class methods
  
  # Given a list of Items, sets the appropriate status
  # TODO: this needs to be broken up and moved into Item.post_hooks
  # to be more efficient
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
  
  # Find Borrowers and get their associated WorkMeta, Classification, Location and Loans in the most
  # efficient way
  # TODO: some of this possibly should be migrated to Item.post_hooks (esp. Loans, Classification and Location) 
  def self.find_eager(ids)
    items = self.find(:all, :conditions=>{:ITEM_ID=>ids}, :include=>[:work_meta, :classification, :location])
    i = {}
    items.each do |item|
      i[item.id] = item
      if item.work_meta
        i[item.id].add_relationship('resource')
      end
    end
    Loan.find_all_by_ITEM_ID_and_CURRENT_LOAN(ids, "T").each do |loan|
      i[loan.ITEM_ID].current_loans ||=[]
      i[loan.ITEM_ID].current_loans << loan
      i[loan.ITEM_ID].add_relationship('actor')
    end
    items
  end   
  
  # ITEM.EDIT_DATE is Item's last-modified field
  def self.last_modified_field
    "EDIT_DATE"
  end
  
  def self.post_hooks(items, format, params)
    if format == 'alto'
      type = []
      status = []
      items.each do |i|
        type << i.TYPE_ID  
        status << i.STATUS_ID
      end
      type_status = {1=>{},6=>{}}
      TypeStatus.find(:all, :conditions=>["(TYPE_STATUS IN (?) AND SUB_TYPE = 1) OR (TYPE_STATUS IN (?) AND SUB_TYPE = 6)", type, status]).each do |ts|
        type_status[ts.SUB_TYPE][ts.TYPE_STATUS] = ts
      end
      items.each do |i|
        i.item_type = type_status[1][i.TYPE_ID]
        i.item_status = type_status[6][i.STATUS_ID]
      end
    end
  end
  
  # Instance methods
  
  # The display message for the item's availability status
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
    elsif self.current_loans.is_a?(Array) and curr_loan = self.current_loans.first
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
  
  # Convenience method to return a boolean reflecting an item's current availability status
  def available?
    return false if self.current_loans.is_a?(Array)

    if self.status
      unless status.TYPE_STATUS == 5
        return false
      end
    end
    true
  end  
  
  # Return an array of categories (should always include 'item')
  # TODO: make the default (item) category locally customizable
  def categories
    add_category('item')
    @categories
  end  
  
  # Returns the amount owed (or predicted) by a particular Borrower on the given Item.
  # Returns a Float.
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
  
  # Record created timestamp
  def created
    self.CREATE_DATE
  end  
  
  # Returns the DAIA service type based on LOAN_TYPE.
  # TODO: this should be locally customizable in config/connector.yml
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
  
  # Returns the projected availability timestamp of an item.  If the item is currently
  # available returns .now()
  def date_available
    if available?
      return DateTime.now
    else
      if self.current_loans.is_a?(Array) && curr_loan = self.current_loans.first
        return curr_loan.DUE_DATE
      end
    end
  end
  
  # Returns the Jangle entry.
  # TODO: this needs to be deprecated into a view.  
  def entry(format)
    {:id=>self.uri,:title=>title,:updated=>self.EDIT_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end  
  
  # Gets the related entities to the Item and sets appropriate categories based on relationship
  # (Loan, Reservation, Interloan, etc.)
  # TODO: this should become a class method, since we don't actually *need*
  # the Items themselves to accomplish this (and would be more efficient)  
  def get_relationships(rel, filter, offset, limit, borrower_id=nil) 
    related_entities = []
    if rel == 'resources'
      related_entities << self.work_meta
    elsif rel == 'actors'
      if filter.nil? or filter == 'loan'
        self.loans.find_all_by_CURRENT_LOAN('T').each do | loan |
          loan.borrower.add_category('loan')
          related_entities << loan.borrower unless borrower_id && borrower_id != loan.borrower.BORROWER_ID
        end
      end
      if filter.nil? or filter == 'hold'
        self.reservations.find(:all, :conditions=>"STATE < 5").each do | rsv |
          rsv.borrower.add_category('hold')
          related_entities << rsv.borrower unless borrower_id && borrower_id != rsv.borrower.BORROWER_ID
        end
      end
      if filter.nil? or filter == 'interloan'
        self.ill_requests.find(:all, :conditions=>"ILL_STATUS < 6").each do | ill |
          ill.borrower.add_category('interloan')
          related_entities << ill.borrower unless borrower_id && borrower_id != ill.borrower.BORROWER_ID
        end      
      end
    end
    related_entities.each do | rel |
      rel.via = self
    end    
    related_entities
  end  
  
  # Because Holdings and Items are merged as Jangle 'items', we need to disambiguate the
  # PK with which table it came from (for Items, use 'I-')  
  def identifier
    "I-#{self.id}"
  end 

  def item_status
    return @item_status || TypeStatus.find_by_TYPE_STATUS_and_SUB_TYPE(self.STATUS_ID, 6)
  end
    
  def item_type
    return @item_type || TypeStatus.find_by_TYPE_STATUS_and_SUB_TYPE(self.TYPE_ID, 1)
  end
  # Create a MARC Format for Holdings Display (MFHD) record
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
  
  # Returns an Array of NCIP Request Types that apply to this Item
  def ncip_request_types
    ncip_types = []
    ncip_types << "Loan" if @categories.index('loan')
    ncip_types << "Hold" if @categories.index('hold')    
    ncip_types
  end  
    
  # Return the title for the feed entry, should be:
  # Available or Unavailable
  # TODO: Perhaps "availability_message" is more appropriate
  def title
    case available?
    when true then "Available"
    else "Unavailable"
    end
  end

  # Returns a Hash to index in Solr.  Note the type, status, location and format attributes to potentially
  # use as categories later
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
  
  # Returns a binary (ISO 27709) MFHD
  def to_marc
    marc.to_marc
  end

  # Returns a MARCXML MFHD
  def to_marcxml
    marc.to_xml
  end  
    
  # Last modified
  def updated
    (self.EDIT_DATE||self.CREATE_DATE||Time.now)
  end
  
end
