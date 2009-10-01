xml.record('xmlns'=>'http://diglib.org/ilsdi/1.1') do | record |
  record.bibliographic("id"=>entity_uri(entity.WORK_ID,'resources'))
  case entity.class
  when Item then render :partial=>dlfexpanded_items, :locals=>{:record=>record, :entity=>entity}
  when Holding then render :partial=>dlfexpanded_holdings, :locals=>{:record=>record, :entity=>entity}
  end
end