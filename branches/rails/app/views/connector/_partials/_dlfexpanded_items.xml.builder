record.items do | items |
  items.item("id"=>entity_uri(entity.id)) do | item |
    item.simpleavailability do | simple |
      simple.identifier entity_uri(entity.id)
      if entity.available?
        simple.availabilitystatus('available')
      else 
        simple.availabilitystatus('not available')
      end
      loc_string = ''
      #if location
      #  loc_string = 'Location: '+location["name"]
      #end
      if entity.CLASS_ID
        loc_string << " - " unless loc_string.empty?
        loc_string << "Shelfmark: #{entity.classification.CLASS_NUMBER} #{entity.SUFFIX}"
      end
      simple.location(loc_string)
      #simple.availabilitymsg(status_message) if status_message
      #simple.dateavailable(date_available.xmlschema) if date_available 
    end
  end
end