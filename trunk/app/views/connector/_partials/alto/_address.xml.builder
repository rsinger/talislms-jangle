xml.alto :Address, :id=>entity.ADDRESS_ID do |address|
  (1..5).each do |line_no|
    next unless entity.attributes["LINE_#{line_no}"]
    address.alto :"line#{line_no}", entity.attributes["LINE_#{line_no}"]
  end
  if entity.POST_CODE
    address.alto :postcode, entity.POST_CODE
  end
  if entity.TELEPHONE_NO
    phone = entity.TELEPHONE_NO
    if entity.EXTENSION
      phone << " ext. #{entity.EXTENSION}"
    end
    address.alto :phone, phone
  end
  if entity.FAX_NO
    address.alto :fax, entity.FAX_NO
  end
  if entity.NOTE
    address.alto :note, entity.NOTE
  end
end