class Recall < AltoModel
  set_table_name 'RECALL_LOAN'
  set_primary_keys :ITEM_ID, :LOAN_ID, :RESERVATION_ID
  belongs_to :reservation
  belongs_to :item
  belongs_to :loan
end