class ConnectorController < ApplicationController
  
  before_filter :init_feed, :except=>[:services, :explain]
  after_filter :sync_models
  
  def feed
    @offset = (params[:offset]||0).to_i

    entity_class = case params[:entity]
    when 'actors' then Borrower
    when 'collections' then Collection
    when 'items' then ItemHoldingCache
    when 'resources' then WorkMeta
    end
    if params[:entity] == 'actors' && (@auth_user && @auth_user.user != :jangle_administrator)
      @entities = [@auth_user.borrower]
      @total = 1
    else
      @entities = entity_class.page(@offset, AppConfig.connector['page_size'])

      if params[:entity] != 'collections'
        @total = @entities.total_results      
      else
        @total = Collection.count
      end
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
    when 'actors'
      if @auth_user && (@auth_user.user == :jangle_administrator || @auth_user.borrower_id == params[:id].to_i)
        Borrower.find(id_translate(params[:id]))
      else
        render :text => "Not Authorized", :status=>401
        return
      end
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
    when 'actors'
      if @auth_user && (@auth_user.user == :jangle_administrator || @auth_user.borrower_id == params[:id].to_i)
        Borrower.find(id_translate(params[:id]))
      else
        render :text => "Not Authorized", :status=>401
        return
      end      
    when 'collections' then Collection.find(id_translate(params[:id]))
    when 'items' then ItemHoldingCache.find(id_translate(params[:id]))
    when 'resources' then WorkMeta.find(id_translate(params[:id]))
    end
    
    @offset = 0
    @entities = []
    entities.each do | entity |
      if params[:entity] == 'actors' && @auth_user.user != :jangle_administrator
        @entities = @entities + entity.get_relationships(params[:entity], params[:filter], @offset, AppConfig.connector['page_size'], @auth_user.borrower_id)
      else
        @entities = @entities + entity.get_relationships(params[:entity], params[:filter], @offset, AppConfig.connector['page_size'])
      end
    end
    @entities.uniq!
    @total = @entities.length
    populate_entities unless @entities.empty?
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
    if !params[:query] || params[:query].empty?
      render :template => 'connector/diagnostics/7.xml.builder', :status => 400, :locals => {:message=>"'query'"}
      return
    end    
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
    unless (diagnostic = base_class.valid_cql_query?(cql)) === true
      render :template => "connector/diagnostics/#{diagnostic[:number]}.xml.builder", :status => 400, :locals => {:message=>diagnostic[:message]}
      return      
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
    if (params[:entity] && params[:entity] == 'actors') || (params[:scope] && params[:scope] == 'actors')
      @auth_user = authenticate
    end
    @connector_base = (request.headers['X_CONNECTOR_BASE']||'/connector')
    @format = determine_format(params)
    #sync_models
  end
  def populate_entities    
    @entities.first.class.find_associations(@entities)
  end
  def determine_format(params)
    # this needs to be fixed so it's appropriate for the entity
    if params[:format]
      return params[:format]
    end
    AppConfig.connector['entities'][params[:entity]]['default']
  end
  
  def sync_models
    [ItemHoldingCache, BorrowerCache, WorkMetaCache].each do | cache |
      spawn(:method => :thread) do
        cache.sync
      end      
    end
    #case params[:entity]
    #when 'items' then ItemHoldingCache.sync
    #when 'actors' then BorrowerCache.sync
    #when 'resources' then WorkMetaCache.sync
    #end
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
  
  private
    def authenticate
      user = nil
      authenticate_or_request_with_http_basic do |id, password| 
        if id == AppConfig.connector['administrator']['username'] && password == AppConfig.connector['administrator']['password']
          user = AuthenticatedUser.new(:user=>:jangle_administrator)
        elsif borrower = Borrower.find_by_BARCODE_and_PIN(id, password)
          user = AuthenticatedUser.new(:user=>id, :password=>password, :borrower=>borrower, :borrower_id=>borrower.BORROWER_ID)
        end
      end
      user
    end
    
    class AuthenticatedUser < OpenStruct
    end

  
end
