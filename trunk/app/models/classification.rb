class Classification < AltoModel
  has_many :items
  set_table_name 'CLASSIFICATION'
  set_primary_key 'CLASS_ID'
end