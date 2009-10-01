module HarvestModel
  
  def fetch_entities(offset,limit)
    results = self.find(:all,:limit=>limit,:offset=>offset,:order=>'edit_date desc')
    ids = []
    results.each do | result |
      ids << result.entity_id
    end

    unless results.first.is_a?(HarvestItem)
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
    else
      entities = self.fetch_originals(results)
      if entities.length < results.length
        mismatch = results.length - entities.length
        puts "Length mismatch: #{mismatch}"      
        # Loop through the HarvestItem resultset and figure out what's not
        # in the original
        bad_ids = []
        results.each do | result |
          match = false
          entities.each do | entity |
            next if (entity.is_a?(Holding) and result.item_type == 'item') or (entity.is_a?(Item) and result.item_type == 'holding')
            next if (entity.is_a?(Holding) and result.holding_id != entity.HOLDING_ID) or (entity.is_a?(Item) and result.item_id != entity.ITEM_ID)
            match = true
            break
          end
          bad_ids << result.id unless match
        end
        unless bad_ids.empty?
          puts "Deleting HarvestItem ids:  #{bad_ids.join(", ")}"
          self.delete(bad_ids)
        end
        entities = entities + self.fetch_entities((offset+limit)-mismatch, mismatch)
      end      
    end
    entities
  end
end