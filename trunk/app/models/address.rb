class Address < AltoModel
  set_table_name 'ADDRESS'
  set_primary_key 'ADDRESS_ID'
  has_many :contact_points, :foreign_key=>'ADDRESS_ID'
end
