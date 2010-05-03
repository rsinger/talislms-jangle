class AltoModel < ActiveRecord::Base
  # AltoModel should never be initialized directly
  self.abstract_class = true 
  
  # Theoretically, there could be a development and production Alto instance
  establish_connection("#{ RAILS_ENV }") 

  attr_reader :uri, :categories, :relationships
  
  # Sets the URI of the Jangle resource.  'base' is derived from the X-Connector-Base HTTP Header
  def set_uri(base, path)
    @uri = "#{base}/#{path}/#{self.identifier}"
  end
  
  def add_relationship(entity_name)
    @relationships ||=[]
    @relationships << entity_name unless @relationships.index(entity_name)
  end
  
  # Sets the Jangle category of the resource.  This is uncontrolled, but should try to reflect the 
  # categories defined in /config/connector.yml (and vice-versa)
  def add_category(category)
    @categories ||=[]
    @categories << category unless @categories.index(category)
  end
  
  #
  # ActiveRecord Overrides  
  #
  # These are intended to prevent Rails from writing to the Sybase DB
  # (instead Jangle should use TalisSOA for these sorts of operations)
  def delete
    raise ActiveRecord::ReadOnlyRecord
  end
  
  def destroy()
    raise ActiveRecord::ReadOnlyRecord
  end
  
  def save()
    raise ActiveRecord::ReadOnlyRecord
  end

  def save!()
    raise ActiveRecord::ReadOnlyRecord
  end  
  
  # Public class methods
  
  # cql_tree_walker takes a parsed CQL query (cql_node) and constructs
  # a SQL query from it
  def self.cql_tree_walker(cql_node)
    if cql_node.is_a?(CqlRuby::CqlTermNode)
      return ["#{cql_index_to_sql_column(cql_node.index)} #{cql_relation_to_sql_relation(cql_node.relation)} ?", [cql_value_to_sql_value(cql_index_to_sql_column(cql_node.index), cql_node.term)]]
    end   
    left_sql, left_args = cql_tree_walker(cql_node.left_node)
    right_sql, right_args = cql_tree_walker(cql_node.right_node)
    if cql_node.is_a?(CqlRuby::CqlOrNode)
      boolean = "OR"
    elsif cql_node.is_a?(CqlRuby::CqlAndNode)
      boolean = "AND"
    end
    return ["(#{left_sql} #{boolean} #{right_sql})", *[left_args + right_args].flatten]
  end
  
  # Determines whether or not a CQL query is valid in the context of
  # Alto's SQL schema
  def self.valid_cql_query?(cql_node)
    if cql_node.is_a?(CqlRuby::CqlTermNode)
      if !cql_index_to_sql_column(cql_node.index)
        return({:number=>16, :message=>cql_node.index})
      end
      if !cql_relation_to_sql_relation(cql_node.relation)
        return({:number=>19, :message=>cql_node.relation})
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
  
  # Turns a CQL sort node into a SQL sort statement
  def self.cql_sort(sort_node)
    sort_strings = []
    sort_node.keys.each do | sort |
      string = cql_index_to_sql_column(sort.base)
      string << " "
      sort.modifiers.each do | mod |
        string << case mod.type
        when "sort.ascending" then "ASC"
        when "sort.descending" then "DESC"
        end
      end
      sort_strings << string
    end
    return sort_strings.join(", ")
  end
  
  # Converts CQL relations into SQL relations
  def self.cql_relation_to_sql_relation(cql_rel)
    set = cql_rel.modifier_set
    relation = set.base
    sql_rel = case relation
    when "==" then "="
    when "<>" then "!="
    else 
      cql_rel.modifier_set.base
    end
    sql_rel
  end
  
  # Set the 'value' of the CQL query node to a relevant
  # datatype for the corresponding SQL column
  def self.cql_value_to_sql_value(col, term)
    column = self.columns_hash[col]
    value = case column.type.to_s
    when "integer" then term.to_i
    when "datetime" then DateTime.parse(term)
    when "date" then DateTime.parse(term)
    else term
    end
    value
  end
  
  # Removes all documents of this particular type from the Solr index
  # and pulls all data in the table into Solr.  
  # .recache commits after every 1000 documents are added and optimizes
  # when the task is completed.
  def self.recache
    offset = 0
    conditions = nil
    # Delete the existing documents from Solr
    r = AppConfig.solr.delete_by_query("model:#{self.name}")
    AppConfig.solr.commit
    # Sybase can't really 'page', so if we sort by primary key, we can 
    # take the last one retrieve and ask for the next 1000 with a PK
    # greater than the last.
    while rows = self.all(:conditions=>conditions, :limit=>1000, :order=>self.primary_key)
      break if rows.empty? # No more records, stop looping
      RAILS_DEFAULT_LOGGER.info "Adding #{self.to_s} at offset: #{offset}"
      docs = []
      rows.each {|row| docs << row.to_doc }
      AppConfig.solr.add docs
      AppConfig.solr.commit 
      offset += 1000
      conditions = ["#{self.primary_key} > #{rows.last.id}"] unless rows.empty?      
      unless docs.empty? # This should never be false at this point
        results = AppConfig.solr.select :q=>"model:#{docs.last[:model]}"
        # Report the number of instances of this model in the logs
        RAILS_DEFAULT_LOGGER.info "#{results["response"]["numFound"]} #{docs.last[:model]} documents in Solr index"
      end
    end    
    # Be sure we've committed the last bunch
    AppConfig.solr.commit 
    # Given that we've deleted and added a bunch of stuff, seems wise to optimize
    AppConfig.solr.optimize     
  end  
  
  # Pulls all rows in the table that have been updated since the given timestamp and
  # adds them to the Solr index.
  def self.sync_from(timestamp)
    # {last_modified_field} is named something different depending on the model.
    conditions = ["#{last_modified_field} >= ?", timestamp]
    # Sort on the timestamp and PK, since a batch process can affect many rows at once
    while rows = self.all(:conditions=>conditions, :limit=>1000, :order=>"#{last_modified_field}, #{primary_key}")
      # If we have nothing or one row that matches the timestamp, we're in sync
      break if rows.empty? or (rows.length == 1 && rows.first.updated == timestamp.xmlschema)
      RAILS_DEFAULT_LOGGER.info "Updating #{self.to_s} from timestamp: #{conditions[1]}"
      docs = []
      rows.each {|row| docs << row.to_doc }
      AppConfig.solr.add docs
      #
      conditions = ["#{last_modified_field} >= ? AND #{primary_key} > ?", rows.last.send(last_modified_field), rows.last.id] unless rows.empty?
      AppConfig.solr.commit
      results = AppConfig.solr.select :q=>"model:#{docs.last[:model]}"
      RAILS_DEFAULT_LOGGER.info "#{results["response"]["numFound"]} #{docs.last[:model]} documents in Solr index"
      # If there are less than 1000 rows, that should be everything
      break if rows.length < 1000
    end    
    AppConfig.solr.commit    
  end
  
  # This is a stub that should be modified by inherited models if they need to anything to the objects
  # dependent on the request, such as context-dependent association queries, etc.
  def self.post_hooks(entities, format, params)
  end
  
  # .page is intended to allow an abstraction between IndexCache and AltoModel.  Since Sybase does
  # not support the concept of paging, the offset parameter is ignored and set to 0.  The 'first'
  # page comes directly from Sybase and Jangle asyncronously syncs Sybase and Solr after the request.
  def self.page(offset, limit)
    result_set =  ResultSet.new(self.all(:limit=>limit, :order=>"#{self.last_modified_field} DESC"))
    result_set.total_results = self.count
    result_set
  end
end