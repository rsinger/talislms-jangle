xml.alto :Holding, :id=>entity.id, :work=>entity.WORK_ID do |holding|
  holding.alto :notes do |note|
    (1..4).each do |i|
      note.alto :"holdings#{i}", entity.attributes["HOLDINGS#{i}"] if entity.attributes["HOLDINGS#{i}"]
      note.alto :"general#{i}", entity.attributes["GENERAL_NOTE#{i}"] if entity.attributes["GENERAL_NOTE#{i}"]       
      note.alto :"descriptive#{i}", entity.attributes["DESCRIPTIVE_NOTE#{i}"] if entity.attributes["DESCRIPTIVE_NOTE#{i}"]   
      note.alto :"wants#{i}", entity.attributes["WANTS_NOTE#{i}"] if entity.attributes["WANTS_NOTE#{i}"]
    end
  end
  if entity.location
    holding.alto :location do |location|
      xml << render(:partial=>"/connector/_partials/alto/location.xml.builder", :locals=>{:entity=>entity.location})
    end
  end
  if entity.classification
    xml << render(:partial=>"/connector/_partials/alto/classification.xml.builder", :locals=>{:entity=>entity.classification})
  end
  if entity.SUFFIX
    holding.alto :classificationSuffix, entity.SUFFIX
  end
end
