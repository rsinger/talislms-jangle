require RAILS_ROOT+'/lib/jdbcsybase_adapter'
require RAILS_ROOT+'/lib/vcard'   
require RAILS_ROOT+'/lib/namespaced_marc_xml'
require RAILS_ROOT+'/lib/index_cache'

BorrowerCache.sync
WorkMetaCache.sync
ItemHoldingCache.sync