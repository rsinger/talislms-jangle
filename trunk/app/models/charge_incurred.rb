class ChargeIncurred < AltoModel
  set_table_name 'CHARGE_INCURRED'
  set_primary_key :CHARGE_INCURRED_ID
  def balance
    credit = FineBalance.sum('AMOUNT', :conditions=>{:INCURRED_ID=>self.CHARGE_INCURRED_ID})
    return self.AMOUNT-credit
  end
end