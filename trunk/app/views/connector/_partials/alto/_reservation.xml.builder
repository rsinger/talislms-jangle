xml.alto :Reservation, :id=>entity.id do |reservation|
  reservation.alto :borrower, entity.BORROWER_ID
  reservation.alto :priority, entity.PRIORITY
  reservation.alto :lastUsefulDateTime, entity.LAST_USEFUL_DATETIME.xmlschema
  reservation.alto :effectiveDateTime, entity.EFFECTIVE_DATETIME.xmlschema
  if entity.COMPLETED_DATETIME
    reservation.alto :completedDateTime, entity.COMPLETED_DATETIME.xmlschema
  end
  if entity.SATISFIED_DATETIME
    reservation.alto :satisfiedDateTime, entity.SATISFIED_DATETIME.xmlschema
  end
  reservation.alto :collectionSite do |site|
    xml << render(:partial=>"/connector/_partials/alto/location.xml.builder", :locals=>{:entity=>entity.location})
  end
  reservation.alto :created, entity.CREATE_DATE.xmlschema
  reservation.alto :lastModified, entity.EDIT_DATE.xmlschema
  entity.links.each do |lnk|
    if lnk.is_a?(Item)
      reservation.alto :Item, :id=>lnk.id
    else
      reservation.alto :WorkMeta, :id=>lnk.id
    end
  end
end