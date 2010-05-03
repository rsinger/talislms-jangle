class ContactPoint < AltoModel
  set_table_name 'CONTACT_POINT'
  set_primary_key nil
  belongs_to :address, :foreign_key=>'ADDRESS_ID'
  belongs_to :borrower, :foreign_key=>"BORROWER_ID"
  attr_accessor :addr
  
  def addr
    @addr || self.address
  end
end
