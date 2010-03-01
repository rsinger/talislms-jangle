class FineBalance < AltoModel
  set_table_name 'CREDIT_VS_INCURRED'
  set_primary_key :CREDIT_ID
  belongs_to :charge_incurred, :foreign_key=>:INCURRED_ID
end