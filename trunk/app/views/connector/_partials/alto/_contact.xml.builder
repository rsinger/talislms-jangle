contact_type = case entity.CONTACT_TYPE
when 0 then "email"
else "unknown"
end
xml.alto :Contact, entity.DISPLAY_VALUE, :type=>contact_type, :preferred=>entity.PREFERRED, :name=>entity.CONTACT_NAME, :startDate=>entity.START_DATE, :endDate=>entity.END_DATE