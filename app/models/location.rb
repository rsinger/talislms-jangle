class Location < AltoModel
  set_table_name 'LOCATION'
  set_primary_key 'LOCATION_ID'
  def loan_rules
    return LoanRule.find_all_by_LOCATION_PROFILE_ID(self.LOCATION_PROFILE_ID)
  end
end