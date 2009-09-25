class HarvestBorrower < ActiveRecord::Base
  extend HarvestModel
  belongs_to :borrower
  alias_method :entity, :borrower

  def entity_id
    self.borrower_id
  end
  def self.sync(full=false)
    last_update = self.find(:first, :order=>'edit_date desc')
    full = true unless last_update

    if full
      delete_all
    end
    complete = false
    offset = 0
    order = 'EDIT_DATE asc'
    conditions = []
    if full
      conditions = 0
    else
      conditions << "EDIT_DATE > '#{last_update.edit_date.to_s}'"
    end
    batch_size = 10000
    while !complete
      if full
        borrowers = Borrower.find_by_sql(["SELECT TOP #{batch_size} * FROM BORROWER WHERE BORROWER_ID > ? ORDER BY BORROWER_ID, EDIT_DATE", conditions])
        puts borrowers.first.BORROWER_ID
        break if borrowers.empty?
        borrowers.each do | borrower |
          harvest_b = self.find_or_create_by_borrower_id(borrower.BORROWER_ID)
          harvest_b.type_id = borrower.TYPE_ID
          harvest_b.status_id = borrower.STATUS
          harvest_b.edit_date = borrower.EDIT_DATE
          unless harvest_b.save
            puts "error saving #{harvest_b.borrower_id}"
          end
          conditions = borrower.BORROWER_ID
        end
        
        puts "Full Borrower sync offset: #{offset + batch_size}"
      else
        Borrower.find(:all, :limit=>1000, :conditions=>conditions, :order=>order).each do | borrower |
          harvest_b = self.find_or_create_by_borrower_id(borrower.BORROWER_ID)
          harvest_b.type_id = borrower.TYPE_ID
          harvest_b.status_id = borrower.STATUS
          harvest_b.edit_date = borrower.EDIT_DATE
          harvest_b.save
        end
        last_update = self.find(:first, :order=>'edit_date desc')
        conditions = ["EDIT_DATE > '#{last_update.edit_date.to_s}'"]
        puts "Incremental Borrower sync from: #{last_update.edit_date.to_s}"
      end
      offset += batch_size
      complete = true if Borrower.count_by_sql("SELECT COUNT(DISTINCT BORROWER_ID) FROM BORROWER WHERE BORROWER_ID > 0") <= self.count

    end
  end 
end
