class Holding < AltoModel
  set_table_name 'SITE_SERIAL_HOLDINGS'
  set_primary_key 'HOLDINGS_ID'
  belongs_to :work_meta, :foreign_key=>"WORK_ID"
end
