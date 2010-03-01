xml.daia :daia, :version=>"0.51", "xsi:schemaLocation"=>"http://ws.gbv.de/daia/ http://ws.gbv.de/daia/daia.xsd",
  :timestamp=>DateTime.now.xmlschema, "daia:xmlns"=>"http://ws.gbv.de/daia/" do | daia |
    daia.daia :document, :id=>entity_uri(entity.WORK_ID, 'resources')
    if entity.classification
      daia.daia :label, "#{entity.classification.CLASS_NUMBER} #{entity.SUFFIX}"
    end
    
    if entity.location
      daia.daia :storage, entity.location.NAME
    end
    
    if (entity.respond_to?("available?") and entity.available?) or entity.class == Holding
      daia.daia :available, :service=>entity.daia_service
    else
      daia.daia :unavailable, :service=>entity.daia_service
    end
end
