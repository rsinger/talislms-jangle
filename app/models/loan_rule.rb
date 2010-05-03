class LoanRule < AltoModel
  set_table_name 'LOAN_RULE'
  set_primary_keys :LOCATION_PROFILE_ID, :BORROWER_TYPE, :ITEM_TYPE, :LOAN_TYPE, :DUE_DATE_ID, :RENEW_DUE_DATE_ID, :RES_DUE_DATE_ID, :RES_RENEW_DUE_DATE_ID
  
  belongs_to :due_date, :foreign_key=>:DUE_DATE_ID
  
  # Returns a Location based on LOCATION_PROFILE_ID
  # FIXME: I'm pretty sure this is totally wrong.
  def location
    return Location.find_by_LOCATION_PROFILE_ID(self.LOCATION_PROFILE_ID)
  end
end