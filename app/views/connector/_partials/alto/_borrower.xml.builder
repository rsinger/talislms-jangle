xml.alto :Borrower, :id=>entity.id do |borrower|
  borrower.alto :barcode, entity.BARCODE
  borrower.alto :"first-names", entity.FIRST_NAMES
  borrower.alto :surname, entity.SURNAME
  borrower.alto :style, entity.STYLE
  if entity.DATE_OF_BIRTH
    borrower.alto :"date-of-birth", entity.DATE_OF_BIRTH.xmlschema
  end
  if entity.REGISTRATION_DATE
    borrower.alto :"registration-date", entity.REGISTRATION_DATE.xmlschema
  end
  if entity.CREATE_DATE
    borrower.alto :"date-created", entity.CREATE_DATE.xmlschema
  end
  if entity.EDIT_DATE
    borrower.alto :"last-modified", entity.EDIT_DATE.xmlschema
  end
  if entity.EXPIRY_DATE
    borrower.alto :"expiration-date", entity.EXPIRY_DATE.xmlschema
  end
  if entity.NOTE
    borrower.alto :note, entity.NOTE
  end
  
  if department = entity.department
    borrower.alto :department do |dept|
      xml << render(:partial=>"/connector/_partials/alto/location.xml.builder", :locals=>{:entity=>department})
    end
  end
  if home = entity.home_site
    borrower.alto :"home-site" do |home_site|
      xml << render(:partial=>"/connector/_partials/alto/location.xml.builder", :locals=>{:entity=>home}) 
    end
  end
  if address = entity.current_address
    borrower.alto :"primary-address"  do |prime_address|
      xml << render(:partial=>"/connector/_partials/alto/address.xml.builder", :locals=>{:entity=>address}) 
    end
  end
  fines = (entity.fine_balance || 0.0).to_s
  (a,b) = fines.split(".")
  fines = "#{a}.#{b.ljust(2, "0")}"
  # Accessing base_currency's attributes directly keeps throwing an error, so use 'attributes' hash
  borrower.alto :"amount-owed", fines, :currency=>AppConfig.connector['base_currency'].attributes["CODE"].strip
  
  entity.contacts.each do |contact|
    xml << render(:partial=>"/connector/_partials/alto/contact.xml.builder", :locals=>{:entity=>contact}) 
  end
  
  borrower.alto :reservations do |res|
    
  end
end