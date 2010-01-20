class AltoModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection("#{ RAILS_ENV }")
  #extend(JdbcSpec::Sybase)
  attr_reader :uri, :categories
  def set_uri(base, path)
    @uri = "#{base}/#{path}/#{self.id}"
  end
  
  def add_category(category)
    @categories ||=[]
    @categories << category unless @categories.index(category)
  end
    
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
  
  def self.recache
    offset = 0
    conditions = nil
    while rows = self.all(:conditions=>conditions, :limit=>1000, :order=>self.primary_key)
      break if rows.empty?
      puts "Adding #{self.to_s} at offset: #{offset}"
      docs = []
      rows.each {|row| docs << row.to_doc }
      docs.each {|doc| AppConfig.solr.add(doc)}
      offset += 1000
      conditions = ["#{self.primary_key} > #{rows.last.id}"] unless rows.empty?
      AppConfig.solr.commit
      unless docs.empty?
        results = AppConfig.solr.select :q=>"model:#{docs.last[:model]}"
        puts "#{results["response"]["numFound"]} #{docs.last[:model]} documents in Solr index"
      end
    end    
    AppConfig.solr.commit      
  end  
  
  def self.sync_from(timestamp)
    conditions = ["#{last_modified_field} >= ?", timestamp]
    while rows = self.all(:conditions=>conditions, :limit=>1000, :order=>last_modified_field)
      break if rows.empty? or (rows.length == 1 && rows.first.updated == timestamp.xmlschema)
      puts "Updating #{self.to_s} from timestamp: #{conditions[1]}"
      docs = []
      rows.each {|row| docs << row.to_doc }
      docs.each {|doc| AppConfig.solr.add(doc)}
      conditions = ["#{last_modified_field} >= ?", rows.last.send(last_modified_field)] unless rows.empty?
      AppConfig.solr.commit
      results = AppConfig.solr.select :q=>"model:#{docs.last[:model]}"
      puts "#{results["response"]["numFound"]} #{docs.last[:model]} documents in Solr index"
      break if rows.empty? or rows.length < 1000
    end    
    AppConfig.solr.commit    
  end
end