class ConnectorController < ApplicationController
  
  before_filter :init_feed, :except=>[:services, :explain]
  def feed
    if params[:offset]
      @offset = params[:offset].to_i
    else
      @offset = 0
    end

    if @offset == 0
      @entities = case params[:entity]
      when 'actors' then Borrower.find(:all, :limit=>AppConfig.connector['page_size'], :include=>[:contacts, :contact_points], :order=>"EDIT_DATE desc")
      when 'collections' then Collection.find(:all, :limit=>AppConfig.connector['page_size'])
      when 'items'
        sync_models
        HarvestItem.fetch_entities(0, AppConfig.connector['page_size'])
      when 'resources' then WorkMeta.find(:all, :limit=>AppConfig.connector['page_size'], :include=>[:items], :order=>"MODIFIED_DATE desc")
      end
      sync_models unless params[:entity] == 'items'
    else
      harvest_class = case params[:entity]
      when 'actors' then HarvestBorrower
      when 'collections' then Collection
      when 'items' then HarvestItem
      when 'resources' then HarvestWork
      end
      unless harvest_class == Collection
        @entities = harvest_class.fetch_entities(@offset, AppConfig.connector['page_size'])
      else
        @entities = Collection.find(:all, :limit=>AppConfig.connector['page_size'], :offset=>@offset)
      end

    end
    if params[:entity] != 'items'
      @total = @entities.first.class.count      
    else
      @total = HarvestItem.count
    end
    populate_entities
    params[:format] = nil if params[:format]
    respond_to do | fmt |
      fmt.json
    end
  end
  
  def filter
    if params[:offset]
      @offset = params[:offset].to_i
    else
      @offset = 0
    end
    
    if @offset == 0
      if params[:entity] == 'items'
        sync_models
      end
      base_class = case params[:entity]
        when 'actors' then Borrower
        when 'collections' then Collection
        when 'items' then HarvestItem
        when 'resources' then WorkMeta
        end
      @total = base_class.count_by_filter(params[:filter])
      if params[:entity] == 'items'
        @entities = base_class.fetch_entities_by_filter(params[:filter], 0, AppConfig.connector['page_size'])
      else
        @entities = base_class.find_by_filter(params[:filter], AppConfig.connector['page_size'])
        sync_models
      end
    else
      harvest_class = case params[:entity]
      when 'actors' then HarvestBorrower
      when 'collections' then Collection
      when 'items' then HarvestItem
      when 'resources' then HarvestWork
      end
      unless harvest_class == Collection
        @entities = harvest_class.fetch_entities_by_filter(params[:filter], @offset, AppConfig.connector['page_size'])
      else
        @entities = Collection.find_by_filter(params[:filter], :limit=>AppConfig.connector['page_size'], :offset=>@offset)
      end
      @total = harvest_class.count_by_filter(params[:filter])

    end
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
    when 'items' then HarvestItem.fetch_originals(HarvestItem.find(id_translate(params[:id])))
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
    when 'items' then HarvestItem.fetch_originals(HarvestItem.find(id_translate(params[:id])))
    when 'resources' then WorkMeta.find(id_translate(params[:id]))
    end
    
    @offset = 0
    @entities = []
    entities.each do | entity |
      @entities = @entities + entity.get_relationships(params[:entity], @offset, AppConfig.connector['page_size'])
    end
    puts @format
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
      when 'items' then HarvestItem
      when 'resources' then WorkMeta
      end
    if cql.is_a?(CqlRuby::CqlSortNode)
        sort = base_class.cql_sort(cql)
        cql = cql.subtree
    else
      sort = nil
    end
    cql_query = base_class.cql_tree_walker(cql)  
    @total = base_class.count(:conditions=>cql_query)
    if params[:entity] == 'items'
      @entities = base_class.fetch_entities_by_sql(cql_query, @offset, limit, sort)      
    else
      @entities = base_class.find(:all, :conditions=>cql_query, :offset=>@offset, :limit=>limit)
    end


    populate_entities
    params[:format] = nil if params[:format]
    respond_to do | fmt |
      fmt.json {render :action=>'feed'}
    end    
    
  end

  private
  def init_feed
    @connector_base = (request.headers['X_CONNECTOR_BASE']||'/connector')
    @format = determine_format(params)
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
    when 'items' then HarvestItem.sync(false)
    when 'actors' then HarvestBorrower.sync(false)
    when 'resources' then HarvestWork.sync(false)
    end
  end
  
  def id_translate(id)
    #if the request is simple (integer, list or nil) return that
    return [] if id.empty?
    return [id.to_i] if id.match(/^\d+$/)
    if id.match(/^(\d+[,;]?)*$/)
      ids = []
      id.split(/[,;]/).each do | i |
        ids << i.to_i
      end
    end
    #if the request includes a range (x-y), translate that into an array
    ids = []
    id.split(/[,;]/).each do | i |
      if i.match(/^\d+$/)
        ids << i.to_i
      else
        start_rng, end_rng = i.split("-")
        (start_rng..end_rng).each { | r | ids << r.to_i }          
      end
    end
    return ids
  end  
end
