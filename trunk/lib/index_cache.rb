class IndexCache

  def self.select(query, offset=0, limit=10, sort=nil)    
    AppConfig.solr.select({:q=>query, :start=>offset, :rows=>limit, :sort=>sort})
  end
  
  def self.prune(cache_results, model_results)
    deletions = []
    cache_results.each do | cache_result |
      unless in_master?(cache_result, model_results)
        deletions << cache_result["id"]
      end
    end
    AppConfig.solr.delete_by_id deletions
  end
  
  def self.in_master?(cache_result, model_results)
    model_results.each do | result |
      return true if result.class.to_s == cache_result["model"] && result.id == cache_result["model_id"]
    end
    false
  end
  
  def self.cql_tree_walker(cql_node)
    if cql_node.is_a?(CqlRuby::CqlTermNode)
      field = cql_index_to_field(cql_node)
      value = cql_value_to_value(cql_node)
      mod = nil
      if field && value
        mod = ":"
      end
      return "#{field}#{mod}#{value}"
    end   
    left = cql_tree_walker(cql_node.left_node)
    right = cql_tree_walker(cql_node.right_node)
    if cql_node.is_a?(CqlRuby::CqlOrNode)
      boolean = "OR"
    elsif cql_node.is_a?(CqlRuby::CqlAndNode)
      boolean = "AND"
    end
    return "(#{left} #{boolean} #{right})"
  end  
  
  def self.valid_cql_query?(cql_node)
    if cql_node.is_a?(CqlRuby::CqlTermNode)
      if !cql_index_to_field(cql_node)
        return({:number=>16, :message=>cql_node.index})
      end
      return true
    end  
    left = valid_cql_query?(cql_node.left_node)
    if left.is_a?(Hash)
      return left
    end
    right = valid_cql_query?(cql_node.right_node)
    if right.is_a?(Hash)
      return right
    end
    return true
  end  
  
end

class ResultSet < Array
  attr_accessor :total_results
end

class BorrowerCache < IndexCache
  def self.all(options={})
    result_set = ResultSet.new
    results = self.select("+model:Borrower",(options[:offset]||0), (options[:limit]||10), "last_modified desc")    
    ids = []
    results["response"]["docs"].each do | doc |
      ids << doc["model_id"]
    end
    borrowers = ResultSet.new(Borrower.find_eager(ids))
    if borrowers.length < ids.length
      prune(results["response"]["docs"], borrowers)
      borrowers = all((options[:offset]||0), (options[:limit]||10))
    end
    borrowers.total_results = results["response"]["numFound"]
    borrowers  
  end
  
  def self.synched?
    borrower = Borrower.find(:first, :order=>"EDIT_DATE DESC")
    cache_borrower = self.select("id:Borrower_#{borrower.BORROWER_ID}",0,1)
    return false unless cache_borrower["response"]["numFound"] > 0
    cache_borrower["response"]["docs"].first["last_modified"] == borrower.to_doc[:last_modified]
  end
  
  def self.sync
    return true if synched?
    last_indexed = self.select("+model:Borrower",0,1, "last_modified desc")
    if last_indexed["response"]["docs"].empty?
      Borrower.recache
    else
      Borrower.sync_from(DateTime.parse(last_indexed["response"]["docs"].first["last_modified"]))
    end
    return synched?
  end
end

class WorkMetaCache < IndexCache
  def self.all(options={})
    results = self.select("+model:WorkMeta",(options[:offset]||0), (options[:limit]||10), "last_modified desc")    
    ids = []
    results["response"]["docs"].each do | doc |
      ids << doc["model_id"]
    end
    works = ResultSet.new(WorkMeta.find_eager(ids))
    if works.length < ids.length
      prune(results["response"]["docs"], works)
      works = all((options[:offset]||0), (options[:limit]||10))
    end
    works.total_results = results["response"]["numFound"]
    works
  end
  
  def self.synched?
    work = WorkMeta.find(:first, :order=>"MODIFIED_DATE DESC")
    cache_work = self.select("id:WorkMeta_#{work.WORK_ID}",0,1)
    return false unless cache_work["response"]["numFound"] > 0
    cache_work["response"]["docs"].first["last_modified"] == work.to_doc[:last_modified]
  end
  
  def self.sync
    return true if synched?
    last_indexed = self.select("+model:WorkMeta",0,1, "last_modified desc")
    if last_indexed["response"]["docs"].empty?
      WorkMeta.recache
    else
      WorkMeta.sync_from(DateTime.parse(last_indexed["response"]["docs"].first["last_modified"]))
    end
    return synched?
  end
  
  def self.find_by_filter(filter, options={})
    options[:offset] ||=0
    options[:limit] ||= AppConfig.connector['page_size']
    results = self.select("+model:WorkMeta +category:#{filter}",(options[:offset]), (options[:limit]), "last_modified desc")    
    ids = []
    results["response"]["docs"].each do | doc |
      ids << doc["model_id"]
    end
    works = ResultSet.new(WorkMeta.find_eager(ids))
    if works.length < ids.length
      prune(results["response"]["docs"], works)
      works = find_by_filter(filter, options)
    end
    works.total_results = results["response"]["numFound"]
    works    
  end    
end

class ItemHoldingCache < IndexCache
  def self.all(options={})
    results = self.select("(model:Item || model:Holding)",(options[:offset]||0), (options[:limit]||10), "last_modified desc")    
    ids = {:items=>[],:holdings=>[]}
    results["response"]["docs"].each do | doc |
      case doc["model"]
      when "Item" then ids[:items] << doc["model_id"]
      when "Holding" then ids[:holdings] << doc["model_id"]
      end
    end
    mismatch = false
    items = nil
    holdings = nil
    unless ids[:items].empty?
      items = Item.find_eager(ids[:items])
      if items.length < ids[:items].length
        prune(results["response"]["docs"], items)      
        mismatch = true
      end
    end
    unless ids[:holdings].empty?
      holdings = Holding.find_eager(ids[:holdings])
      if holdings.length < ids[:holdings].length
        prune(results["response"]["docs"], holdings)      
        mismatch = true
      end    
    end
    if mismatch
      item_holdings = self.all(options)
    else
      if items && holdings
        item_holdings = collate(items, holdings)
      else
        item_holdings = ResultSet.new case
        when items then items
        when holdings then holdings
        end
      end
    end
    item_holdings.total_results = results["response"]["numFound"]
    item_holdings
  end
  
  def self.find_by_cql(query, options)
    results = self.select("#{query} AND (model:Item || model:Holding)",(options[:offset]||0), (options[:limit]||10), options[:sort])    
    ids = {:items=>[],:holdings=>[]}
    results["response"]["docs"].each do | doc |
      case doc["model"]
      when "Item" then ids[:items] << doc["model_id"]
      when "Holding" then ids[:holdings] << doc["model_id"]
      end
    end
    mismatch = false
    items = nil
    holdings = nil
    unless ids[:items].empty?
      items = Item.find_eager(ids[:items])
      if items.length < ids[:items].length
        prune(results["response"]["docs"], items)      
        mismatch = true
      end
    end
    unless ids[:holdings].empty?
      holdings = Holding.find_eager(ids[:holdings])
      if holdings.length < ids[:holdings].length
        prune(results["response"]["docs"], holdings)      
        mismatch = true
      end    
    end
    if mismatch
      item_holdings = self.find_by_cql(query, options)
    end
    if items && holdings
      item_holdings = collate(items, holdings)
    else
      item_holdings = ResultSet.new case
      when items then items
      when holdings then holdings
      end
    end
    item_holdings.total_results = results["response"]["numFound"]
    item_holdings    
    
  end
  
  def self.cql_sort(sort_node)
    sort_strings = []
    sort_node.keys.each do | sort |
      string = case sort.base
      when /rec.identifier/i then "model_id"
      when /rec.lastModificationDate/i then "last_modified"
      end
      string << " "
      sort.modifiers.each do | mod |
        string << case mod.type
        when "sort.ascending" then "asc"
        when "sort.descending" then "desc"
        end
      end
      sort_strings << string
    end
    return sort_strings.join(", ")
  end  
  
  def self.cql_index_to_field(cql_node)
    field = nil
    if cql_node.index =~ /rec.identifier/i
      if cql_node.term =~ /^[HI]/
        field = "id"
      else
        field = "model_id"
      end
    elsif cql_node.index =~ /rec.lastModificationDate/i
      field = "last_modified"
    end
    if cql_node.relation && cql_node.relation.modifier_set.base == "<>" && field
      field = "-#{field}"
    end
    field
  end
  
  def self.cql_value_to_value(cql_node)
    field = false
    value = false
    if cql_node.index =~ /rec.identifier/i    
      if cql_node.term =~ /^[HI]/
        t, id = cql_node.value.split("-")
        value = case t
          when "I" then "Item_#{id}"
          when "H" then "Holding_#{id}"
          end
      else
        value = cql_node.term
      end
      field = true
    end
    if cql_node.index =~ /rec.lastModificationDate/i   
      d = DateTime.parse(cql_node.term)
      d.utc
      value = d.strftime("%Y-%m-%dT%H:%M:%SZ")
      field = true
    end
    if cql_node.relation && (cql_node.relation.modifier_set.base == ">" or cql_node.relation.modifier_set.base == ">=")
      value = "[#{value} TO *]" 
    end
    if cql_node.relation && (cql_node.relation.modifier_set.base == "<" or cql_node.relation.modifier_set.base == "<=")
      value = "[* TO #{value}]" 
    end    
    if cql_node.relation && cql_node.relation.modifier_set.base == "<>" && !field
      value = "-#{value}"
    end
    value
  end
  
  def self.find_by_filter(filter, options={})
    results = self.select("+model:#{filter.capitalize}",(options[:offset]||0), (options[:limit]||10), "last_modified desc")    
    ids = {:items=>[],:holdings=>[]}
    results["response"]["docs"].each do | doc |
      case doc["model"]
      when "Item" then ids[:items] << doc["model_id"]
      when "Holding" then ids[:holdings] << doc["model_id"]
      end
    end
    ids = {:items=>[],:holdings=>[]}
    results["response"]["docs"].each do | doc |
      case doc["model"]
      when "Item" then ids[:items] << doc["model_id"]
      when "Holding" then ids[:holdings] << doc["model_id"]
      end
    end
    mismatch = false
    items = nil
    holdings = nil
    unless ids[:items].empty?
      items = Item.find_eager(ids[:items])
      if items.length < ids[:items].length
        prune(results["response"]["docs"], items)      
        mismatch = true
      end
    end
    unless ids[:holdings].empty?
      holdings = Holding.find_eager(ids[:holdings])
      if holdings.length < ids[:holdings].length
        prune(results["response"]["docs"], holdings)      
        mismatch = true
      end    
    end
    if mismatch
      item_holdings = self.find_by_filter(filter, options)
    else
      if items && holdings
        item_holdings = collate(items, holdings)
      else
        item_holdings = ResultSet.new case
        when items then items
        when holdings then holdings
        end
      end
    end
    item_holdings.total_results = results["response"]["numFound"]
    item_holdings
  end  
  
  def self.collate(items, holdings)
    item_holdings = ResultSet.new
    items.each do | item |
      item_holdings.each do |ih|
        if item.updated > ih.updated
          item_holdings.insert(item_holdings.index(ih), item)
          break
        end
      end
      unless item_holdings.index(item)
        item_holdings << item
      end      
    end
    holdings.each do | holding |
      item_holdings.each do |ih|
        if holding.updated > ih.updated
          item_holdings.insert(item_holdings.index(ih), holding)
          break
        end
      end
      unless item_holdings.index(holding)
        item_holdings << holding
      end
    end
    item_holdings    
  end
  
  def self.find(ids)
    i = {:items=>[],:holdings=>[]}
    [*ids].each do |id|
      model,ident=id.split("-",2)
      case model
      when "I" then i[:items] << ident.to_i
      else i[:holdings] << ident.to_i
      end
    end
    items = Item.all(:conditions=>{:ITEM_ID=>i[:items]})
    holdings = Holding.all(:conditions=>{:HOLDINGS_ID=>i[:holdings]})    
    collate(items, holdings)
  end
  
  def self.synched?
    item = Item.find(:first, :order=>"EDIT_DATE DESC")
    cache_item = self.select("id:Item_#{item.ITEM_ID}",0,1)
    return false unless cache_item["response"]["numFound"] > 0
    return false unless cache_item["response"]["docs"].first["last_modified"] == item.to_doc[:last_modified]
    holdings = Holding.find_by_sql("SELECT TOP 1 h.*, w.MODIFIED_DATE FROM SITE_SERIAL_HOLDINGS h, WORKS_META w WHERE h.WORK_ID = w.WORK_ID ORDER BY w.MODIFIED_DATE DESC")
    cache_holding = self.select("id:Holding_#{holdings.first.HOLDINGS_ID}",0,1)
    return false unless cache_holding["response"]["numFound"] > 0
    return false unless cache_holding["response"]["docs"].first["last_modified"] == holdings.first.to_doc[:last_modified]   
    true 
  end
  
  def self.sync
    return true if synched?
    last_indexed = self.select("+model:Item",0,1, "last_modified desc")
    if last_indexed["response"]["docs"].empty?
      Item.recache
    else
      Item.sync_from(DateTime.parse(last_indexed["response"]["docs"].first["last_modified"]))
    end
    last_indexed = self.select("+model:Holding",0,1, "last_modified desc")
    if last_indexed["response"]["docs"].empty?
      Holding.recache
    else
      Holding.sync_from(DateTime.parse(last_indexed["response"]["docs"].first["last_modified"]))
    end    
    return synched?
  end
end
  