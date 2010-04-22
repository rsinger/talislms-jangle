class ReservationLink < AltoModel
  set_table_name 'RESERVED_LINK'
  set_primary_keys :RESERVATION_ID, :TARGET_ID, :TYPE
  belongs_to :reservation
  
  def link
    case self.TYPE
    when 0 then Item.find(self.TARGET_ID)
    when 1 then Work.find(self.TARGET_ID)
    end
  end
end