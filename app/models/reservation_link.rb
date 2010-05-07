class ReservationLink < AltoModel
  set_table_name 'RESERVED_LINK'
  set_primary_keys :RESERVATION_ID, :TARGET_ID, :TYPE
  belongs_to :reservation
  
  # For the link in question, return the appropriate Work or Item.
  def link
    case self.TYPE
    when 0 then Item.find_eager(self.TARGET_ID)
    when 1 then WorkMeta.find_eager(self.TARGET_ID)
    end
  end
end