xml.alto :Item, :id=>entity.id, :work=>entity.WORK_ID do |item|
  item.alto :barcode, entity.BARCODE.strip if entity.BARCODE
  item.alto :activeSite do |active_site|
    xml << render(:partial=>"/connector/_partials/alto/location.xml.builder", :locals=>{:entity=>entity.location})
  end
  item.alto :value, entity.VALUE, :currency=>AppConfig.connector['base_currency'].attributes['CODE'].strip
  item.alto :notes do | notes |
    if entity.WANTS_NOTE
      notes.alto :wants, entity.WANTS_NOTE
    end
    if entity.DESC_NOTE
      notes.alto :descriptive, entity.DESC_NOTE
    end    
    if entity.GEN_NOTE
      notes.alto :general, entity.GEN_NOTE
    end    
    if entity.CONTENT_NOTE
      notes.alto :content, entity.CONTENT_NOTE
    end    
  end
  if entity.created
    item.alto :created, entity.created.xmlschema
  end
  if entity.updated
    item.alto :lastModified, entity.updated.xmlschema
  end
  if entity.classification
    xml << render(:partial=>"/connector/_partials/alto/classification.xml.builder", :locals=>{:entity=>entity.classification})
  end  
  if entity.SUFFIX
    item.alto :classificationSuffix, entity.SUFFIX
  end
  item.alto :availability, entity.available?
  item.alto :availabilityMessage, entity.availability_message
  item.alto :dateAvailable, entity.date_available.xmlschema if entity.date_available
  item.alto :"format", entity.FORMAT_ID
  if item_type = entity.item_type
    item.alto :itemType, item_type.NAME, :code=>item_type.CODE
  end  
  if status = entity.item_status
    item.alto :status, status.NAME, :code=>status.CODE
  end  
  if entity.categories && entity.categories.index('hold')
    
  end
end