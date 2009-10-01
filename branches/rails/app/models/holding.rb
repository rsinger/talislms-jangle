class Holding < AltoModel
  set_table_name 'SITE_SERIAL_HOLDINGS'
  set_primary_key 'HOLDINGS_ID'
  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  has_one :harvest_item, :foreign_key=>'holding_id'
  def title 
    (1..4).each do | holdings_note |
      note = self.send("HOLDINGS#{holdings_note}")
      return note unless note.nil? or note.empty?
    end
    "Holdings not available"
  end
  
  def updated
    self.work_meta.MODIFIED_DATE
  end
  
  def relationships
    relationships = nil
    if self.WORK_ID
      relationships = {'http://jangle.org/rel/related#Resources' => "#{self.id}/resources/"}
    end
  end  
  
  def categories
    ['holding']
  end
  
  def entry(format)

    {:id=>self.uri,:title=>self.NAME,:updated=>self.work_meta.MODIFIED_DATE,:content=>self.send(format.to_sym),
      :format=>AppConfig.connector['record_types'][format]['uri'],:relationships=>relationships,
      :content_type=>AppConfig.connector['record_types'][format]['content-type']}
  end  
  
  def self.find_associations(entities)
  end
  def self.find_eager(ids)
    return self.find(ids, :include=>[:work_meta, :harvest_items])
  end  
end
