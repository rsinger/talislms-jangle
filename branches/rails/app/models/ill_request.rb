class IllRequest < AltoModel
  set_table_name 'ILL_REQUEST'
  set_primary_key 'ILL_ID'
  belongs_to :borrower, :foreign_key=>'BORROWER_ID'
  belongs_to :item, :foreign_key=>'ITEM_ID'
  belongs_to :work_meta, :foreign_key=>'WORK_ID'
end
