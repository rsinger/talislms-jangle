xml.alto :Collection, :id=>entity.id, :interloans=>entity.interloan?.to_s do | collection |
  collection.alto :code, entity.CODE
  collection.alto :name, entity.NAME
  collection.alto :note, entity.NOTE
end