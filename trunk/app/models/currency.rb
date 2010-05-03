class Currency < AltoModel
  set_table_name 'CURRENCY'
  set_primary_key 'CURRENCY_ID'
  
  # Returns the base currency set for the LMS.
  def self.base_currency
    return self.find_by_BASE_CURRENCY('T')
  end
end