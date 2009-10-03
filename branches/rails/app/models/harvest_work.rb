class HarvestWork < ActiveRecord::Base
  extend HarvestModel
  belongs_to :work_meta
  alias_method :entity, :work_meta
  def entity_id
    self.work_meta_id
  end
  
  def self.sync(full=false)
    last_update = self.find(:first, :order=>'edit_date desc')
    full = true unless last_update

    if full
      delete_all
    end
    complete = false
    offset = 0
    order = 'MODIFIED_DATE asc'
    conditions = []
    unless full
      conditions << "MODIFIED_DATE > '#{last_update.edit_date.to_s}'"
    end

    while !complete
      if full
        i = nil
        WorkMeta.find(:all, :limit=>10000, :conditions=>conditions, :order=>'WORK_ID asc').each do | work |
          harvest_work = self.find_or_create_by_work_meta_id(work.WORK_ID)
          harvest_work.suppress_from_opac = case work.SUPPRESS_FROM_OPAC
          when 'T' then true
          when 'F' then false
          else nil
          end
          harvest_work.suppress_from_index = case work.SUPPRESS_FROM_INDEX
          when 'T' then true
          when 'F' then false
          else nil
          end            
          harvest_work.edit_date = work.MODIFIED_DATE
          harvest_work.save
          i = work.WORK_ID
        end
        conditions = ["WORK_ID > #{i}"]
        puts "Full Work_Meta sync offset: #{offset + 1000}"
      else
        WorkMeta.find(:all, :limit=>1000, :conditions=>conditions, :order=>order).each do | work |
          harvest_work = self.find_or_create_by_work_meta_id(work.WORK_ID)
          harvest_work.suppress_from_opac = case work.SUPPRESS_FROM_OPAC
          when 'T' then true
          when 'F' then false
          else nil
          end
          harvest_work.suppress_from_index = case work.SUPPRESS_FROM_INDEX
          when 'T' then true
          when 'F' then false
          else nil
          end
          harvest_work.edit_date = work.MODIFIED_DATE
          harvest_work.save
        end
        last_update = self.find(:first, :order=>'edit_date desc')
        conditions = ["MODIFIED_DATE > '#{last_update.edit_date.to_s}'"]
        puts "Incremental Work_Meta sync from: #{last_update.edit_date.to_s}"
      end
      offset += 1000
      complete = true if WorkMeta.count_by_sql("SELECT COUNT(DISTINCT WORK_ID) FROM WORKS_META WHERE WORK_ID > 0") <= self.count

    end
  end
  
  def self.find_by_filter(filter, offset, limit)
    if filter == 'opac'
      works = self.find_all_by_suppress_from_opac_and_suppress_from_work('F','F', :limit=>limit, :offset=>offset, :order=>"edit_date desc")
    end    
    ids = []
    works.each do | result |
      ids << result.entity_id
    end

    entities = self.find_eager(ids)
    if entities.length < results.length
      mismatch = results.length - entities.length
      puts "Length mismatch: #{mismatch}"      
      ent_ids = []
      entities.each do | entity |
        ent_ids << entity.id
      end
      puts ent_ids.inspect
      bad_ids = ids - ent_ids
      bad_ids.each do | bad_id |
        puts "Bad id: #{bad_id}"

        results.each do | result |
          if result.entity_id == id
            puts "Result match #{result}"
            d = self.delete(result.id)
            puts "#{d} items deleted"
          end
        end

      end
      entities = entities + self.find_by_filter(filter, (offset+limit)-mismatch, mismatch)
    end    
    entities
  end  
end
