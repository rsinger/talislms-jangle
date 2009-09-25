class Borrower < AltoModel
  set_table_name 'BORROWER'
  set_primary_key 'BORROWER_ID'
  has_many :items, :through=>:loans
  has_many :loans, :foreign_key => 'BORROWER_ID'
  has_many :reservations, :foreign_key=>'BORROWER_ID'
  has_many :ill_requests, :foreign_key=>"BORROWER_ID"
  has_many :contact_points, :foreign_key=>"BORROWER_ID"
  has_many :addresses, :through=>:contact_points
  has_many :contacts, :foreign_key=>"TARGET_ID"
  #acts_as_solr :fields=> [{:BORROWER_ID=>:integer}, {:BARCODE=>:string},
  #  {:SURNAME=>:string}, {:FIRST_NAMES=>:string},{:EDIT_DATE=>:date}]
  attr_accessor :has_items, :current_address
  def vcard
    vcard = Vpim::Vcard::Maker.make2 do | vc |
      vc.add_name do | name |
        name.family = self.SURNAME if self.SURNAME && !self.SURNAME.strip.empty?
        name.given = self.FIRST_NAMES if self.FIRST_NAMES && !self.FIRST_NAMES.strip.empty?
        name.prefix = self.STYLE if self.STYLE && !self.STYLE.strip.empty?
      end
 
      if address = self.current_address
        vc.add_addr do | addr |
          place = []
          ("1".."5").each do | line |
            if l = address.send("LINE_#{line}")
              place << l 
            end
          end
          addr.street = place[0..(place.length - 2)].join(", ")
          addr.locality = place.last
          addr.preferred = true
          addr.location = address.NAME if address.NAME
          addr.postalcode = address.POST_CODE if address.POST_CODE
          if address.TELEPHONE_NO and !address.TELEPHONE_NO.strip.empty?          
            vc.add_tel(address.TELEPHONE_NO) {|p| p.location = addr.location}
          end
        end
      end
      self.contacts.each do | contact |
        next unless contact.PREFERRED == "T"
        vc.add_email(contact.DISPLAY_VALUE) if contact.DISPLAY_VALUE && !contact.DISPLAY_VALUE.strip.empty?
      end
      vc.add_uid(self.BARCODE,"X-BARCODE")
      vc.add_uid(self.uri, "http://jangle.org/terms/#URI")
    end
    vcard.to_s    
  end
  
  def self.find_associations(entity_list)
    ids = []
    entities = {}
    entity_list.each do | entity |
      ids << entity.id
      entities[entity.id] = entity
    end
    Address.find_by_sql(["SELECT a.*, cp.BORROWER_ID, cp.NAME FROM ADDRESS a, CONTACT_POINT cp WHERE cp.BORROWER_ID IN (?)
      AND cp.ADDRESS_ID = a.ADDRESS_ID AND cp.CURRENT_CONTACT_POINT = 'T'", ids]).each do | address |
      entities[address.BORROWER_ID].current_address = address
    end
    Loan.find_all_by_BORROWER_ID_and_CURRENT_LOAN(ids, 'T').each do | loan |
      entities[loan.BORROWER_ID].has_items = true
      ids.delete(loan.BORROWER_ID)
    end
    if ids.length > 0
      Reservation.find(:all, :conditions=>["BORROWER_ID IN (?) AND STATE < 5", ids]).each do | rsv |
        entities[rsv.BORROWER_ID].has_items = true
        ids.delete(rsv.BORROWER_ID)
      end
    end      
    if ids.length > 0
      IllRequest.find(:all, :conditions=>["BORROWER_ID IN (?) AND ILL_STATUS < 6", ids]).each do | ill |
        entities[ill.BORROWER_ID].has_items = true
      end
    end    
  end
  
  def title
    "#{self.FIRST_NAMES} #{self.SURNAME}"
  end
  
  def entry(format)
    relationships = {}
    if self.has_items
      relationships['http://jangle.org/rel/related#Item'] = "#{self.uri}/items/"
    end
    
    {:id=>self.uri,:title=>self.title,:updated=>self.EDIT_DATE, :created=> self.CREATE_DATE, :content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],
      :content_type=>AppConfig.connector['record_types'][format]['content-type'],:relationships=>relationships}
  end
  
  def self.find_eager(ids)
    self.find(ids, :include=>[:contacts, :contact_points])
  end
end