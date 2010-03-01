namespace :jangle do
  desc "Syncs the Alto Sybase database with the local cache"
  task :sync => :environment do
    [HarvestBorrower, HarvestWork, HarvestItem].each do | harvest_model |
      harvest_model.sync(true)
    end
  end
end