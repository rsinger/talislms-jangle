class Reservation < AltoModel
  set_table_name 'RESERVATION'
  set_primary_key 'RESERVATION_ID'
  belongs_to :borrower, :foreign_key=>"BORROWER_ID"
  belongs_to :item, :foreign_key=>"SATISFYING_ITEM_ID"
  belongs_to :location, :foreign_key=>"COLLECTION_SITE"
  
  # Reservations are linked to both WORKS and ITEM depending on when a reservation has been satisfied.
  # This method returns all objects (Work and Item) associated with the reservation.
  def links
    links = []
    ReservationLink.find_all_by_RESERVATION_ID(self.RESERVATION_ID).each do |link|
      links << link.link
    end
    links
  end
end
