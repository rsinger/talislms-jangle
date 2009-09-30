class Holding < AltoModel
  set_table_name 'SITE_SERIAL_HOLDINGS'
  set_primary_key 'HOLDINGS_ID'
  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  
  def entry(format)
    relationships = {}
    if self.WORK_ID
      relationships['http://jangle.org/rel/related#Work'] = "#{self.uri}/resources/"
    end
    {:id=>self.uri,:title=>self.NAME,:updated=>self.work_meta.MODIFIED_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end  
  def dlfexpanded
    xml = Builder::XmlMarkup.new
    xml.record('xmlns'=>'http://diglib.org/ilsdi/1.1') do | record |
      record.bibliographic("id"=>self.WORK_ID)
      record.items do | item |
        items.item("id"=>uri) do | item |
          item.simpleavailability do | simple |
            simple.identifier uri
            if available
              simple.availabilitystatus('available')
            else 
              simple.availabilitystatus('not available')
            end
            loc_string = ''
            if location
              loc_string = 'Location: '+location["name"]
            end
            if self.CLASS_ID
              loc_string << " - " unless loc_string.empty?
              loc_string << "Shelfmark: #{self.classification.CLASS_NUMBER} #{self.classification.suffix}"
            end
            simple.location(locString)
            simple.availabilitymsg(status_message) if status_message
            simple.dateavailable(date_available.xmlschema) if date_available 
          end
        end
      end
    end
    return xml.target!
  end  
end
