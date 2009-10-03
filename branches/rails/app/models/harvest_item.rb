class HarvestItem < ActiveRecord::Base
  extend HarvestModel
  belongs_to :item
  alias_method :entity, :item
  def entity_id
    self.item_id
  end
  
  def self.sync(full=false)
    last_item_update = self.find(:first, :conditions=>["item_type = 'item'"], :order=>'edit_date desc')
    last_holding_update = self.find(:first, :conditions=>["item_type = 'holding'"], :order=>'edit_date desc')    
    full = true unless last_item_update and last_holding_update
    if full
      delete_all
      self.full_item_sync
      self.full_holding_sync
    else
      self.incremental_item_sync(last_item_update.edit_date)
      self.incremental_holding_sync(last_holding_update.edit_date)
    end
  end
  
  def self.item_to_harvest_item(item)
    harvest_item = HarvestItem.find_or_create_by_item_id(item.ITEM_ID)
    harvest_item.type_id = item.TYPE_ID
    harvest_item.status_id = item.STATUS_ID
    harvest_item.edit_date = item.EDIT_DATE
    harvest_item.item_type = 'item'
    harvest_item.location_id = item.ACTIVE_SITE_ID
    harvest_item.format_id = item.FORMAT_ID
    harvest_item.save    
    return harvest_item
  end
  
  def self.holding_to_harvest_item(holding)
    harvest_item = HarvestItem.find_or_create_by_holding_id(holding.HOLDINGS_ID)
    harvest_item.edit_date = holding.work_meta.MODIFIED_DATE
    harvest_item.item_type = 'holding'
    harvest_item.location_id = holding.LOCATION_ID
    harvest_item.save
    return harvest_item    
  end
  
  def self.full_item_sync
    batch_size = 10000
    offset = 0
    item_id = 0
    puts "Full sync of Item to HarvestItem starting now."
    until self.items_synced?
      Item.find_by_sql(["SELECT TOP #{batch_size} * FROM ITEM WHERE ITEM_ID > ? ORDER BY ITEM_ID, EDIT_DATE", item_id]).each do | item |
        self.item_to_harvest_item(item)
        item_id = item.ITEM_ID
      end  
      offset += batch_size
      puts "Full Item to HarvestItem sync offset: #{offset}"    
    end
  end
  
  def self.full_holding_sync    
    batch_size = 10000
    offset = 0
    holding_id = 0
    puts "Full sync of Holding to HarvestItem starting now."
    until self.holdings_synced?
      Holding.find_by_sql(["SELECT TOP #{batch_size} s.*, w.MODIFIED_DATE FROM SITE_SERIAL_HOLDINGS s, WORKS_META w WHERE s.HOLDINGS_ID > ? AND s.WORK_ID = w.WORK_ID ORDER BY s.HOLDINGS_ID, w.MODIFIED_DATE",holding_id]).each do | holding |
        self.holding_to_harvest_item(holding)
        holding_id = holding.HOLDINGS_ID
      end
      offset += batch_size
      puts "Full Holding to HarvestItem sync offset: #{offset}"       
    end
  end
  
  def self.incremental_item_sync(date)
    i = 0
    puts "Incremental sync of Item to HarvestItem starting now."
    Item.find_by_sql(["SELECT ITEM.* FROM ITEM WHERE EDIT_DATE >= ?", date]).each do | item |
      self.item_to_harvest_item(item)
      i += 1
    end
    puts "#{i} item(s) synced."
  end
  
  def self.incremental_holding_sync(date)
    i = 0
    puts "Incremental sync of Holding to HarvestItem starting now."
    Holding.find_by_sql(["SELECT h.*, w.MODIFIED_DATE FROM SITE_SERIAL_HOLDINGS h, WORKS_META w WHERE h.WORK_ID = w.WORK_ID AND w.MODIFIED_DATE >= ?", date]).each do | holding |
      self.holding_to_harvest_item(holding)
      i += 1
    end
    puts "#{i} holding(s) synced."
  end
  
  def self.items_synced?
    return true if Item.count_by_sql("SELECT COUNT(DISTINCT ITEM_ID) FROM ITEM WHERE ITEM_ID >= 0") <= self.count_by_sql("SELECT count(id) FROM harvest_items WHERE item_type = 'item'")
    false
  end
  
  def self.holdings_synced?
    return true if Holding.count_by_sql("SELECT COUNT(DISTINCT HOLDINGS_ID) FROM SITE_SERIAL_HOLDINGS, WORKS_META WHERE HOLDINGS_ID >= 0 AND SITE_SERIALS_HOLDINGS.WORK_ID = WORKS_META.WORK_ID") <= self.count_by_sql("SELECT count(id) FROM harvest_items WHERE item_type = 'holding'")
    false
  end
  
  def self.fetch_originals(harvest_items)
    item_ids = []
    holding_ids = []
    harvest_items.each do | hi |
      case hi.item_type
      when 'item' then item_ids << hi.item_id
      when 'holding' then holding_ids << hi.holding_id
      end
    end
    items = Item.find_eager(item_ids)
    holdings = Holding.find_eager(holding_ids)
    combo = []
    harvest_items.each do | hi |
      if hi.item_type == 'item'
        items.each do |item|
          if item.ITEM_ID == hi.item_id
            combo << item
            break
          end
        end
      else
        holdings.each do |holding|
          if holding.HOLDINGS_ID == hi.holding_id
            combo << holding
            break
          end
        end        
      end
    end
    combo 
  end
  
  def self.find_by_filter(filter, offset, limit)
    if filter == 'item'
      items = self.find_all_by_item_type('item', :limit=>limit, offset=>offset, :order=>"edit_date desc")
    elsif filter == 'holding'
      items = self.find_all_by_item_type('holding', :limit=>limit, offset=>offset, :order=>"edit_date desc")      
    end    
    self.fetch_originals(items)
  end  
end
