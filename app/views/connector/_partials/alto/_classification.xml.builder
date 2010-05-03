xml.alto :Classification, :id=>entity.id do |classification|
  classification.alto :scheme, entity.CLASS_AREA_ID.strip
  classification.alto :classnumber, entity.CLASS_NUMBER
  classification.alto :"feature-heading", entity.FEATURE_HEADING
  classification.alto :"filing-key", entity.FILING_KEY
  if entity.PRIOR_ID && entity.PRIOR_ID > 0
    classification.alto :"prior-id", entity.PRIOR_ID
  end
end