namespace :jangle do
  namespace :cache do
    desc "Syncs the Alto Sybase database with the local cache"
    task :sync => :environment do
      [BorrowerCache, WorkMetaCache, ItemHoldingCache].each do | cache_model |
        cache_model.sync
      end
    end
    desc "Wipes the local cache and completely resynchronized the Solr cache"
    task :clean => :environment do
      [Borrower, WorkMeta, Item, Holding].each do | model |
        model.recache
      end      
    end
  end
end