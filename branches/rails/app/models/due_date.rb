class DueDate < AltoModel
  set_table_name 'DUE_DATE'
  set_primary_key :DUE_DATE_ID
  has_many :loan_rules
end