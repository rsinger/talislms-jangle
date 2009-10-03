xml.dlf :record, 'dlf:xmlns'=>'http://diglib.org/ilsdi/1.1' do | record |
  record.dlf :bibliographic, "id"=>entity_uri(entity.WORK_ID,'resources')
  xml << case entity.class.to_s
  when "Item" then render(:partial=>"/connector/_partials/dlfexpanded_items.xml.builder", :locals=>{:entity=>entity})
  when "Holding" then render(:partial=>"/connector/_partials/dlfexpanded_holdings.xml.builder", :locals=>{:entity=>entity})
  end
end