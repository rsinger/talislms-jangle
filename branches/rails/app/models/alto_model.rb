class AltoModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection("alto_#{ RAILS_ENV }")
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
end