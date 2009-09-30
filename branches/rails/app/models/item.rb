class Item < AltoModel
  set_table_name 'ITEM'
  set_primary_key 'ITEM_ID'

  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  has_many :borrowers, :through=>:loans
  has_many :loans, :foreign_key=>"ITEM_ID"
  belongs_to :classification, :foreign_key=>"CLASS_ID"
  attr_accessor :uri
  def entry(format)
    relationships = {}
    if self.WORK_ID
      relationships['http://jangle.org/rel/related#Work'] = "#{self.uri}/resources/"
    end
    {:id=>self.uri,:title=>self.NAME,:updated=>self.EDIT_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end  
  def dlfexpanded
    xml = Builder::XmlMarkup.new
    xml.record('xmlns'=>'http://diglib.org/ilsdi/1.1') do | record |
      record.bibliographic("id"=>self.WORK_ID)
      record.items do | items |
        items.item("id"=>self.uri) do | item |
          item.simpleavailability do | simple |
            simple.identifier uri
            if available?
              simple.availabilitystatus('available')
            else 
              simple.availabilitystatus('not available')
            end
            loc_string = ''
            #if location
            #  loc_string = 'Location: '+location["name"]
            #end
            if self.CLASS_ID
              loc_string << " - " unless loc_string.empty?
              loc_string << "Shelfmark: #{self.classification.CLASS_NUMBER} #{self.SUFFIX}"
            end
            simple.location(loc_string)
            #simple.availabilitymsg(status_message) if status_message
            #simple.dateavailable(date_available.xmlschema) if date_available 
          end
        end
      end
    end
    return xml.target!
  end
  
  def available?
    loans = self.loans.find_by_CURRENT_LOAN('Y')
    if loans
      return false
    end
    true
  end

end
