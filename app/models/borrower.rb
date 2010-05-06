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

  attr_accessor :current_address, :via, :fine_balance, :home_site, :department
  
  # Nothing special needs to be done to an Item PK
  alias :identifier :id
  
  # Class methods
  
  # Maps the CQL query index terms to the appropriate SQL column names
  def self.cql_index_to_sql_column(index)  
    column = case index
      when "rec.identifier" then "BORROWER_ID"
      when "jangle.username" then "BARCODE"
      when "jangle.password" then "PIN"
      when "rec.lastModificationDate" then "EDIT_DATE"
      when "rec.creationDate" then "CREATE_DATE"
      end
    column
  end
  
  # Given a list of Borrowers, makes the appropriate associations
  # TODO: this needs to be broken up and moved into Borrower.post_hooks
  # to be more efficient
  def self.find_associations(entity_list)
  end  

  # Find Borrowers and get their associated contacts, contact points and reservations in the most
  # efficient way
  # TODO: some of this possibly should be migrated to Borrower.post_hooks
  def self.find_eager(ids)
    self.find(:all, :conditions=>{:BORROWER_ID => ids}, :include=>[:contacts, :contact_points, :reservations])
  end
  
  # ITEM.EDIT_DATE is Item's last_modified
  def self.last_modified_field
    "EDIT_DATE"
  end
  
  # Return the first 'page' of borrowers.  If offset is greater than zero, uses BorrowerCache instead.
  def self.page(offset, limit)
    if offset > 0
      return BorrowerCache.page(offset, limit)
    end
    result_set =  ResultSet.new(self.all(:limit=>limit, :order=>"#{self.last_modified_field} DESC", :include=>[:contacts, :contact_points]))
    result_set.total_results = self.count
    result_set
  end  
  
  # TODO: put the relationships here.
  def self.post_hooks(borrowers, format, params)
    entities = {}
    ids = []
    locations = []
    borrowers.each do | entity |
      ids << entity.id
      entities[entity.id] = entity
      if format == 'alto'
        locations << entity.HOME_SITE_ID
        locations << entity.DEPARTMENT_ID
        locations.uniq!
      end
    end

    Address.find_by_sql(["SELECT a.*, cp.BORROWER_ID, cp.NAME FROM ADDRESS a, CONTACT_POINT cp WHERE cp.BORROWER_ID IN (?)
        AND cp.ADDRESS_ID = a.ADDRESS_ID AND cp.CURRENT_CONTACT_POINT = 'T'", ids]).each do | address |
        entities[address.BORROWER_ID].current_address = address
    end    

    if ids.length > 0
      Reservation.find_by_sql(["SELECT DISTINCT r.BORROWER_ID, rl.TYPE as reservation_type FROM RESERVATION r, RESERVED_LINK rl WHERE r.RESERVATION_ID = rl.RESERVATION_ID AND r.STATE < 5 and r.BORROWER_ID IN (?)", entities.keys]).each do |rsv| 
        if rsv.attributes['reservation_type'] == 0
          entities[rsv.BORROWER_ID].add_relationship 'item'
          ids.delete(rsv.BORROWER_ID)          
        else
          entities[rsv.BORROWER_ID].add_relationship 'resource'
        end
      end

    end    
    Loan.find_by_sql(["SELECT DISTINCT BORROWER_ID FROM LOAN WHERE BORROWER_ID IN (?) AND CURRENT_LOAN = 'T'", ids]).each do | loan |
      entities[loan.BORROWER_ID].add_relationship 'item'
      ids.delete(loan.BORROWER_ID)
    end
    
    if ids.length > 0
      IllRequest.find(:all, :conditions=>["BORROWER_ID IN (?) AND ILL_STATUS < 6", ids]).each do | ill |
        entities[ill.BORROWER_ID].add_relationship 'item'
      end
    end 
    
    if format == 'alto'
      locs = {}
      Location.find(:all, :conditions=>["LOCATION_ID IN (?)", locations]).each do |loc|
        locs[loc.id] = loc
      end
      contact_points = {}
      borrowers.each do |b|
        b.department = locs[b.DEPARTMENT_ID] if b.DEPARTMENT_ID
        b.home_site = locs[b.HOME_SITE_ID] if b.HOME_SITE_ID
      end

    end
  end
  
  # Post hook.  Given a Borrower or array of Borrowers, set the fine_balance attribute. 
  def self.set_fine_balances(borrowers)
    b = {}
    [*borrowers].each do | borrower |
      b[borrower.BORROWER_ID] = borrower
    end
    ChargeIncurred.find_by_sql(["SELECT CI.BORROWER_ID, sum(CI.AMOUNT) as fine_balance from CHARGE_INCURRED CI WHERE CI.BORROWER_ID IN (?) GROUP BY CI.BORROWER_ID", b.keys]).each do | charge |
      b[charge.BORROWER_ID].fine_balance = charge.fine_balance.to_f
    end
    
    FineBalance.find_by_sql(["SELECT FB.BORROWER_ID, sum(FB.AMOUNT) as credit FROM CREDIT_VS_INCURRED FB WHERE FB.BORROWER_ID IN (?) GROUP BY FB.BORROWER_ID", b.keys]).each do |credit|
      b[credit.BORROWER_ID].fine_balance ||=0.00
      b[credit.BORROWER_ID].fine_balance -= credit.credit.to_f
    end
  end  
  
  # Serialize the Borrower to a Vcard v 3.0
  # See: http://tools.ietf.org/html/rfc2425 and http://tools.ietf.org/html/rfc2426
  def to_vcard
    vcard = Vpim::Vcard::Maker.make2 do | vc |
      vc.add_name do | name |
        name.family = self.SURNAME.gsub(/\017/,'') if self.SURNAME && !self.SURNAME.strip.empty?
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
      #vc.add_uid(self.uri, "http://jangle.org/terms/#URI")
    end
    vcard.to_s    
  end
  
  # Return a Hash to store in Solr
  def to_doc
    edit_date = (self.EDIT_DATE||self.CREATE_DATE||Time.now)
    edit_date.utc
    doc = {:id=>"Borrower_#{self.BORROWER_ID}", :last_modified=>edit_date.xmlschema, :model=>self.class.to_s, :model_id=>self.BORROWER_ID}
    doc[:type_id] = self.TYPE_ID
    doc[:status_id] = self.STATUS    
    doc[:title] = self.title.gsub(/\020/,'')
    doc
  end  
  
  # Returns a "title" string for the feed responses.  In the development
  # environment, there were some strange control character that were throwing
  # exceptions, so those are removed here.
  def title
    "#{self.FIRST_NAMES} #{self.SURNAME.gsub(/\017/,'') if self.SURNAME}"
  end
  
  def updated
    (self.EDIT_DATE||self.CREATE_DATE||Time.now)
  end
  
  def created
    self.CREATE_DATE if self.CREATE_DATE
  end
     
  # Returns the categories as an array.
  def categories
    @categories
  end
  
  # Returns the Jangle entry.
  # TODO: this needs to be deprecated into a view.
  def entry(format)       
    {:id=>self.uri,:title=>self.title,:updated=>self.EDIT_DATE, :created=> self.CREATE_DATE, :content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],
      :content_type=>AppConfig.connector['record_types'][format]['content-type'],:relationships=>relationships}
  end
    
  # Gets the related entities to the Borrower and sets appropriate categories
  # TODO: this should become a class method, since we don't actually *need*
  # the Borrowers themselves to accomplish this (and would be more efficient)
  def get_relationships(rel, filter, offset, limit)
    related_entities = []
    if rel == 'items'
      if filter.nil? || filter == "loan"
        self.loans.find_all_by_CURRENT_LOAN('T').each do | loan |
          loan.item.add_category('loan')
          related_entities << loan.item
        end
      end
      if filter.nil? || filter == "hold"
        self.reservations.find(:all, :conditions=>"STATE < 5").each do | rsv |
          rsv.links.each do | link |
            next unless link.is_a?(Item)          
            link.add_category('hold')
            related_entities << link
          end
        end
      end
      if filter.nil? || filter == "interloan"
        self.ill_requests.find(:all, :conditions=>"ILL_STATUS < 6").each do | ill |
          ill.item.add_category('interloan')
          related_entities << ill.item
        end     
      end
    elsif rel == 'resources'
      if filter.nil? || filter == "hold"
        self.reservations.find(:all, :conditions=>"STATE < 5").each do | rsv |
          rsv.links.each do | link |
            next unless link.is_a?(WorkMeta)          
            link.add_category('hold')
            related_entities << link
          end
        end
      end      
    end
    related_entities.each do | rel |
      rel.via = self
    end
    related_entities
  end

  # Return the Location object of the Borrower's home site.
  # TODO: make this an attribute and move the SQL call to a post_hook.
  # Call only if the attribute isn't set.
  def home_site
    return @home_site if @home_site
    return Location.find(self.HOME_SITE_ID) if self.HOME_SITE_ID && !self.HOME_SITE_ID.gsub(/\s/,'').empty?
  end
  
  # Return the Location object of the Borrower's department (if set, if valid).
  # TODO: make this an attribute and move the SQL call to a post_hook.
  # Call only if the attribute isn't set.  
  def department
    return @department if @department
    return Location.find(self.DEPARTMENT_ID) if self.DEPARTMENT_ID && !self.DEPARTMENT_ID.gsub(/\s/,'').empty?
  end

end
