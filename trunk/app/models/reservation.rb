class Reservation < AltoModel
  set_table_name 'RESERVATION'
  set_primary_key 'RESERVATION_ID'
  belongs_to :borrower, :foreign_key=>"BORROWER_ID"
  belongs_to :item, :foreign_key=>"SATISFYING_ITEM_ID"
  
  def links
    links = []
    ReservationLink.find_all_by_RESERVATION_ID(self.RESERVATION_ID).each do |link|
      links << link.link
    end
    links
  end
end
