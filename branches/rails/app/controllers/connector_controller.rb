class ConnectorController < ApplicationController
  before_filter :init_feed
  def feed
    if params[:offset]
      offset = params[:offset].to_i
    else
      offset = 0
    end

    if offset == 0
      @entities = case params[:entity]
      when 'actors' then Borrower.find(:all, :limit=>AppConfig.connector['page_size'], :include=>[:contacts, :contact_points], :order=>"EDIT_DATE desc")
      when 'collections' then Collection.find(:all, :limit=>AppConfig.connector['page_size'])
      when 'items' then Item.find(:all, :limit=>AppConfig.connector['page_size'], :order=>"EDIT_DATE desc")
      when 'resources' then WorkMeta.find(:all, :limit=>AppConfig.connector['page_size'], :include=>[:items], :order=>"MODIFIED_DATE desc")
      end
      sync_models
    else
      harvest_class = case params[:entity]
      when 'actors' then HarvestBorrower
      when 'collections' then Collection
      when 'items' then HarvestItem
      when 'resources' then HarvestWork
      end
      unless harvest_class == Collection
        @entities = harvest_class.fetch_entities(offset, AppConfig.connector['page_size'])
      else
        @entities = Collection.find(:all, :limit=>AppConfig.connector['page_size'], :offset=>offset)
      end

    end
    @feed.offset = offset
    @feed.total_results = @entities.first.class.count
    populate_feed
    render :json=>@feed.to_hash
  end
  
  def filter
    if params[:offset]
      offset = params[:offset].to_i
    else
      offset = 0
    end

    if offset == 0
      @entities = case params[:entity]
      when 'actors' then Borrower.find_by_filter(params[:filter], AppConfig.connector['page_size'])
      when 'collections' then Collection.find_by_filter(params[:filter], AppConfig.connector['page_size'])
      when 'items' then Item.find_by_filter(params[:filter], AppConfig.connector['page_size'])
      when 'resources' then WorkMeta.find_by_filter(params[:filter], AppConfig.connector['page_size'])
      end
      sync_models
    else
      harvest_class = case params[:entity]
      when 'actors' then HarvestBorrower
      when 'collections' then Collection
      when 'items' then HarvestItem
      when 'resources' then HarvestWork
      end
      unless harvest_class == Collection
        @entities = harvest_class.fetch_entities_by_filter(params[:filter], offset, AppConfig.connector['page_size'])
      else
        @entities = Collection.find_by_filter(params[:filter], :limit=>AppConfig.connector['page_size'], :offset=>offset)
      end

    end
    @feed.offset = offset
    @feed.total_results = @entities.first.class.count
    populate_feed
    render :json=>@feed.to_hash    
  end
  
  # Returns entities specifically request by id, whether single ids, comma delimited lists or ranges
  def show
    @entities = case params[:entity]
    when 'actors' then Borrower.find_all_by_BORROWER_ID(id_translate(params[:id]))
    when 'collections' then Collection.find_all_by_COLLECTION_ID(id_translate(params[:id]))
    when 'items' then Item.find_all_by_ITEM_ID(id_translate(params[:id]))
    when 'resources' then WorkMeta.find_all_by_WORK_ID(id_translate(params[:id]))
    end
    @feed.offset = 0
    @feed.total_results = @entities.length
    populate_feed
    render :json=>@feed.to_hash    
  end

  private
  def init_feed
    @feed = Feed.new(request.headers['REQUEST_URI'])
    @feed.base = (request.headers['X_CONNECTOR_BASE']||'/connector')
    @feed.entity = params[:entity]    
  end
  def populate_feed    
    @entities.first.class.find_associations(@entities)
    format = determine_format(params)
    @entities.each do | entity |
      entity.set_uri(@feed.base, @feed.entity)
      @feed << entity.entry(format)
    end
    @feed.set_alternate_formats(AppConfig.connector)
    @feed.set_stylesheets(AppConfig.connector, format)
  end
  def determine_format(params)
    # this needs to be fixed so it's appropriate for the entity
    if params[:format]
      return params[:format]
    end
    return AppConfig.connector['entities'][params[:entity]]['record_types'].first
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
