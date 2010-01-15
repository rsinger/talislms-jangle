xml.dlf :items do | items |
  items.dlf :item, "id"=>entity_uri(entity.identifier) do | item |
    item.dlf :simpleavailability do | simple |
      simple.dlf :identifier, entity_uri(entity.identifier)
      if entity.available?
        simple.dlf :availabilitystatus, 'available'
      else 
        simple.dlf :availabilitystatus, 'not available'
      end
      loc_string = ''
      #if location
      #  loc_string = 'Location: '+location["name"]
      #end
      if entity.CLASS_ID
        loc_string << " - " unless loc_string.empty?
        loc_string << "Shelfmark: #{entity.classification.CLASS_NUMBER} #{entity.SUFFIX}" if entity.classification
      end
      simple.dlf :location, loc_string
      if entity.availability_message
        simple.dlf :availabilitymsg, entity.availability_message 
      end
      #simple.dateavailable(date_available.xmlschema) if date_available 
    end
    item << entity.to_marcxml.to_s
  end
end