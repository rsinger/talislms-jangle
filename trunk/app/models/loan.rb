class Loan < AltoModel
  set_table_name 'LOAN'
  set_primary_key 'LOAN_ID'
  belongs_to :borrower, :foreign_key=>"BORROWER_ID"
  belongs_to :item, :foreign_key=>"ITEM_ID"
  
  # Calculate the fines accrued for a particular loan
  # TODO: is this still used?
  def fines
    balance = 0.00
    ChargeIncurred.find(:all, :conditions=>{:TRANSACTION_ID=>self.LOAN_ID, :BORROWER_ID=>self.BORROWER_ID, :TRANSACTION_TYPE=>0}).each do | charge |
      balance += charge.balance
    end
    balance
  end
end
