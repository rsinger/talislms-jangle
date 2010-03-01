class Reservation < AltoModel
  set_table_name 'RESERVATION'
  set_primary_key 'RESERVATION_ID'
  belongs_to :borrower, :foreign_key=>"BORROWER_ID"
  belongs_to :item, :foreign_key=>"SATISFYING_ITEM_ID"
end
