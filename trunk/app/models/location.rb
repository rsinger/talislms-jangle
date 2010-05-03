class Location < AltoModel
  set_table_name 'LOCATION'
  set_primary_key 'LOCATION_ID'
  
  # Return the LoanRules appropriate for a particular LocationProfile
  # FIXME: All of this should probably go through LOCATION_PROFILE, not LOCATION
  def loan_rules
    return LoanRule.find_all_by_LOCATION_PROFILE_ID(self.LOCATION_PROFILE_ID)
  end
end