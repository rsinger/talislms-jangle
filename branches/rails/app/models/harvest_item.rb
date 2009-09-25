class HarvestItem < ActiveRecord::Base
  extend HarvestModel
  belongs_to :item
  alias_method :entity, :item
  def entity_id
    self.item_id
  end
  
  def self.sync(full=false)
    last_update = self.find(:first, :order=>'edit_date desc')
    full = true unless last_update

    if full
      delete_all
    end
    complete = false
    item_complete = false
    holding_complete = false
    offset = 0
    order = 'EDIT_DATE asc'
    conditions = []
    if full
      item = Item.find(:first, :order=>["ITEM_ID"])
      item_id = (item.id.to_i - 1)
      holding = Holding.find(:first, :order=>["HOLDINGS_ID"])
      holding_id = (holding.id.to_i - 1)
    else
      item_conditions << "EDIT_DATE > '#{last_update.edit_date.to_s}'"
      holding_conditions = last_update.edit_date.to_s
    end
    batch_size = 10000
    while !complete
      if full
        i = nil
        unless item_complete
          Item.find_by_sql(["SELECT TOP #{batch_size} * FROM ITEM WHERE ITEM_ID > ? ORDER BY ITEM_ID, EDIT_DATE", item_id]).each do | item |
            harvest_item = HarvestItem.find_or_create_by_item_id(item.ITEM_ID)
            harvest_item.type_id = item.TYPE_ID
            harvest_item.status_id = item.STATUS_ID
            harvest_item.edit_date = item.EDIT_DATE
            harvest_item.item_type = 'item'
            harvest_item.location_id = item.ACTIVE_SITE_ID
            harvest_item.format_id = item.FORMAT_ID
            harvest_item.save
            item_id = item.ITEM_ID
          end      
        end 
        unless holding_complete
          Holding.find_by_sql(["SELECT TOP #{batch_size} s.*, w.MODIFIED_DATE FROM SITE_SERIAL_HOLDINGS s, WORKS_META w WHERE s.HOLDINGS_ID > ? AND s.WORK_ID = w.WORK_ID ORDER BY s.HOLDINGS_ID, w.MODIFIED_DATE",holding_id]).each do | holding |
            harvest_item = HarvestItem.find_or_create_by_holding_id(holding.HOLDINGS_ID)
            harvest_item.edit_date = holding.work_meta.MODIFIED_DATE
            harvest_item.item_type = 'holding'
            harvest_item.location_id = holding.LOCATION_ID
            harvest_item.save
            holding_id = holding.HOLDINGS_ID
          end      
        end             
        puts "Full Item/Harvest sync offset: #{offset + batch_size}"
      else
        unless item_complete
          Item.find(:all, :limit=>batch_size, :conditions=>item_conditions, :order=>order).each do | item |
            harvest_item = HarvestItem.find_or_create_by_item_id(item.ITEM_ID)
            harvest_item.type_id = item.TYPE_ID
            harvest_item.status_id = item.STATUS_ID
            harvest_item.edit_date = item.EDIT_DATE
            harvest_item.item_type = 'item'
            harvest_item.location_id = item.ACTIVE_SITE_ID
            harvest_item.format_id = item.FORMAT_ID          
            harvest_item.save          
          end
        end
        unless holding_complete
          Holding.find_by_sql(["SELECT h.*, w.MODIFIED_DATE FROM SITE_SERIAL_HOLDINGS h, WORKS_META w WHERE h.WORK_ID = w.WORK_ID AND
            w.MODIFIED_DATE > ", holding_conditions]).each do | holding |
            harvest_item = HarvestItem.find_or_create_by_holding_id(holding.HOLDINGS_ID)
            harvest_item.edit_date = holding.MODIFIED_DATE
            harvest_item.item_type = 'holding'
            harvest_item.location_id = holding.LOCATION_ID
            harvest_item.save            
          end
        end
        last_update = self.find(:first, :order=>'edit_date desc')
        item_conditions = ["EDIT_DATE > '#{last_update.edit_date.to_s}'"]
        holding_conditions = last_update.edit_date.to_s
        puts "Incremental Item/Holding sync from: #{last_update.edit_date.to_s}"
      end       
      offset += batch_size
      item_complete = true if Item.count_by_sql("SELECT COUNT(DISTINCT ITEM_ID) FROM ITEM WHERE ITEM_ID >= 0") <= self.count_by_sql("SELECT count(id) FROM harvest_items WHERE item_type = 'item'")
      holding_complete = true if Holding.count_by_sql("SELECT COUNT(DISTINCT HOLDINGS_ID) FROM SITE_SERIAL_HOLDINGS WHERE HOLDINGS_ID >= 0") <= self.count_by_sql("SELECT count(id) FROM harvest_items WHERE item_type = 'holding'")
      complete = true if item_complete and holding_complete      
    end
  end
end
