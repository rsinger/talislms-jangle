require 'active_record/connection_adapters/jdbc_adapter'
module ActiveRecord

  module ConnectionAdapters
    class JdbcTypeConverter
      def choose_type(ar_type)
        procs = AR_TO_JDBC_TYPES[ar_type]
        types = @types
        procs.each do |p|
          new_types = types.reject {|r| r["data_type"].to_i == Jdbc::Types::OTHER}
          new_types = new_types.select(&p)
          new_types = new_types.inject([]) do |typs,t|
            typs << t unless typs.detect {|el| el['type_name'].downcase == t['type_name'].downcase}
            typs
          end
          return new_types.first if new_types.length == 1
          types = new_types if new_types.length > 0
        end
        raise "unable to choose type for #{ar_type} from:\n#{types.collect{|t| t['type_name']}.inspect}"
      end
    end
    
    class JdbcAdapter
      def exec_stored_procedure(sql, name = nil)
        log(sql, name) do
          @connection.execute_query(sql)
        end
      end
    end      
  end
end




#module TSqlMethods
#  def add_limit_offset!(sql, options)
#    if options[:limit] and options[:offset]
#      total_rows = select_all("SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT\\1 TOP 1000000000")}) tally".gsub(/\bORDER BY #{options[:order]}\b/i,''))[0]["TotalRows"].to_i
#      if (options[:limit] + options[:offset]) >= total_rows
#        options[:limit] = (total_rows - options[:offset] >= 0) ? (total_rows - options[:offset]) : 0
#      end
#      sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i, "SELECT * FROM (SELECT TOP #{options[:limit]} * FROM (SELECT\\1 TOP #{options[:limit] + options[:offset]} ")
#      sql << ") AS tmp1"
#      if options[:order]
#        options[:order] = options[:order].split(',').map do |field|
#          parts = field.split(" ")
#          tc = parts[0]
#          if sql =~ /\.\[/ and tc =~ /\./ # if column quoting used in query
#            tc.gsub!(/\./, '\\.\\[')
#            tc << '\\]'
#          end
#          if sql =~ /#{tc} AS (t\d_r\d\d?)/
#              parts[0] = $1
#          elsif parts[0] =~ /\w+\.(\w+)/
#            parts[0] = $1
#          end
#          parts.join(' ')
#        end.join(', ')
#        sql << " ORDER BY #{change_order_direction(options[:order])}) AS tmp2 ORDER BY #{options[:order]}"
#      else
#        sql << " ) AS tmp2"
#      end
#      puts sql
#    elsif sql !~ /^\s*SELECT (@@|COUNT\()/i
#      sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i) do
#        "SELECT#{$1} TOP #{options[:limit]}"
#      end unless options[:limit].nil?
#    end
#  end
#end