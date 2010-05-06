xml.alto :Classification, :id=>entity.id do |classification|
  classification.alto :scheme, entity.CLASS_AREA_ID.strip
  classification.alto :classnumber, entity.CLASS_NUMBER
  classification.alto :featureHeading, entity.FEATURE_HEADING
  classification.alto :filingKey, entity.FILING_KEY
  if entity.PRIOR_ID && entity.PRIOR_ID > 0
    classification.alto :priorId, entity.PRIOR_ID
  end
end