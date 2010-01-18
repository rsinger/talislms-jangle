class ConnectorController < ApplicationController
  
  before_filter :init_feed, :except=>[:services, :explain]
  def feed
    @offset = (params[:offset]||0).to_i

    entity_class = case params[:entity]
    when 'actors' then BorrowerCache
    when 'collections' then Collection
    when 'items' then ItemHoldingCache
    when 'resources' then WorkMetaCache
    end

    @entities = entity_class.all(:limit=>AppConfig.connector['page_size'], :offset=>@offset)

    if params[:entity] != 'collections'
      @total = @entities.total_results      
    else
      @total = Collection.count
    end
    populate_entities
    params[:format] = nil if params[:format]
    respond_to do | fmt |
      fmt.json
    end
  end
  
  def filter
    @offset = (params[:offset]||0).to_i

    entity_class = case params[:entity]
    when 'actors' then BorrowerCache
    when 'collections' then Collection
    when 'items' then ItemHoldingCache
    when 'resources' then WorkMetaCache
    end
    
    @entities = entity_class.find_by_filter(params[:filter], {:offset=>@offset,:limit=>AppConfig.connector['page_size']})

    @total = @entities.total_results      

    populate_entities
    params[:format] = nil if params[:format]
    respond_to do | fmt |
      fmt.json {render :action=>'feed'}
    end
  end
  
  # Returns entities specifically request by id, whether single ids, comma delimited lists or ranges
  def show
    @entities = case params[:entity]
    when 'actors' then Borrower.find(id_translate(params[:id]))
    when 'collections' then Collection.find(id_translate(params[:id]))
    when 'items' then ItemHoldingCache.find(id_translate(params[:id]))
    when 'resources' then WorkMeta.find(id_translate(params[:id]))
    end
    @offset = 0
    @total = @entities.length
    populate_entities
    params[:format] = nil if params[:format]
    respond_to do | fmt |
      fmt.json {render :action=>'feed'}
    end
  end
  
  # Returns the entity relationship feed
  def relationship
    entities = case params[:scope]
    when 'actors' then Borrower.find(id_translate(params[:id]))
    when 'collections' then Collection.find(id_translate(params[:id]))
    when 'items' then ItemHoldingCache.find(id_translate(params[:id]))
    when 'resources' then WorkMeta.find(id_translate(params[:id]))
    end
    
    @offset = 0
    @entities = []
    entities.each do | entity |
      @entities = @entities + entity.get_relationships(params[:entity], @offset, AppConfig.connector['page_size'])
    end
    @entities.uniq!
    @total = @entities.length
    populate_entities
    params[:format] = nil if params[:format]
    respond_to do | fmt |
      fmt.json {render :action=>'feed'}
    end    
    
  end
  
  def explain
    @connector_base = (request.headers['X_CONNECTOR_BASE']||'/connector')
    @config = AppConfig.connector
    respond_to do | fmt |
      fmt.json
    end
  end
  
  # Returns a services request
  def services
    @config = AppConfig.connector
    respond_to do | fmt |
      fmt.json
    end    
  end
  
  def search
    parser = CqlRuby::CqlParser.new
    cql = parser.parse(params[:query])

    if params[:offset]
      @offset = params[:offset].to_i
    else
      @offset = 0
    end
    if params[:count]
      limit = params[:count].to_i
    else
      limit = AppConfig.connector['page_size']
    end
    

    if params[:entity] == 'items'
      sync_models
    end
    base_class = case params[:entity]
      when 'actors' then Borrower
      when 'collections' then Collection
      when 'items' then ItemHoldingCache
      when 'resources' then WorkMeta
      end
    if cql.is_a?(CqlRuby::CqlSortNode)
        sort = base_class.cql_sort(cql)
        cql = cql.subtree
    else
      sort = nil
    end
    cql_query = base_class.cql_tree_walker(cql)  
    if params[:entity] == 'items'
      @entities = base_class.find_by_cql(cql_query, {:offset=>@offset, :limit=>limit, :sort=>sort})      
      @total = @entities.total_results
    else

      @total = base_class.count(:conditions=>cql_query)      
      @entities = base_class.find(:all, :conditions=>cql_query, :offset=>@offset, :limit=>limit)
    end


    populate_entities if @entities.length > 0
    params[:format] = nil if params[:format]
    respond_to do | fmt |
      fmt.json {render :action=>'feed'}
    end    
    
  end

  private
  def init_feed
    @connector_base = (request.headers['X_CONNECTOR_BASE']||'/connector')
    @format = determine_format(params)
    sync_models
  end
  def populate_entities    
    @entities.first.class.find_associations(@entities)
  end
  def determine_format(params)
    puts params.inspect
    # this needs to be fixed so it's appropriate for the entity
    if params[:format]
      return params[:format]
    end
    AppConfig.connector['entities'][params[:entity]]['default']
  end
  
  def sync_models
    case params[:entity]
    when 'items' then ItemHoldingCache.sync
    when 'actors' then BorrowerCache.sync
    when 'resources' then WorkMetaCache.sync
    end
  end
  
  def id_translate(id)
    #if the request is simple (integer, list or nil) return that
    return [] if id.empty?
    return [id.to_i] if id.match(/^\d+$/)
    return [id] if id.match(/^[HI]-\d+$/)
    ids = []
    id.split(/[,;]/).each do | i |
      if i.match(/^([HI]-)?\d+$/)
        if i =~ /^[HI]/
          ids << i
        else
          ids << i.to_i
        end
      else
        start_rng, end_rng = i.split(/[^HI]-/)
        (start_rng..end_rng).each { | r | 
          if r =~ /^[HI]/
            ids << r
          else
            ids << r.to_i 
          end
        }          
      end
    end
    return ids
  end  
end
