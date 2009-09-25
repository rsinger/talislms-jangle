module HarvestModel
  
  def fetch_entities(offset,limit)
    results = self.find(:all,:limit=>limit,:offset=>offset,:order=>'edit_date desc')
    ids = []
    results.each do | result |
      ids << result.entity_id
    end
    entities = results.first.entity.class.find_eager(ids)
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
            d = result.class.delete(result.id)
            puts "#{d} items deleted"
          end
        end

      end
      entities = entities + self.fetch_entities((offset+limit)-mismatch, mismatch)
    end
    entities
  end
end