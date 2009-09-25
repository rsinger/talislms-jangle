class Loan < AltoModel
  set_table_name 'LOAN'
  set_primary_key 'LOAN_ID'
  belongs_to :borrower, :foreign_key=>"BORROWER_ID"
  belongs_to :item, :foreign_key=>"ITEM_ID"
end
