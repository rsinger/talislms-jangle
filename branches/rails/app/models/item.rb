class Item < AltoModel
  set_table_name 'ITEM'
  set_primary_key 'ITEM_ID'
  #acts_as_solr :fields=>[{:ITEM_ID=>:integer},{:EDIT_DATE=>:date}]
  belongs_to :work_meta, :foreign_key=>"WORK_ID"
  has_many :borrowers, :through=>:loans
  has_many :loans, :foreign_key=>"ITEM_ID"
  def self.sync(full=false)
    last_update = self.find_by_solr("ITEM_ID > -100", {:order=>'EDIT_DATE desc', :limit=>1})
    full = true unless last_update.total > 0

    if full
      
    end
    complete = false
    offset = 0
    order = 'EDIT_DATE asc'
    conditions = []
    unless full
      conditions << "EDIT_DATE > '#{last_update.results.first.EDIT_DATE.to_s}'"
    end
    batch_size = 10000
    while !complete
      if full
        i = nil
        Item.find(:all, :limit=>batch_size, :offset=>offset).each do | item |
          item.solr_save
        end
        puts "Full Item sync offset: #{offset + batch_size}"
      else
        Item.find(:all, :limit=>batch_size, :conditions=>conditions, :order=>order).each do | item |
          item.solr_save
        end
        last_update = self.find_by_solr("*:*", {:order=>'EDIT_DATE desc', :limit=>1})
        conditions = ["EDIT_DATE > '#{last_update.results.first.EDIT_DATE.to_s}'"]
        puts "Incremental Item sync from: #{last_update.results.first.EDIT_DATE.to_s}"
      end
      offset += batch_size
      complete = true if Item.count < offset
    end
  end
end
