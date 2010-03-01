class Contact < AltoModel
  set_table_name 'CONTACT'
  set_primary_key 'CONTACT_ID'
  belongs_to :borrower, :foreign_key=>'TARGET_ID'
end
