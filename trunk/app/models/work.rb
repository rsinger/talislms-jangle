class Work < AltoModel
  set_table_name 'WORKS'
  set_primary_key 'WORK_ID'
  attr_accessor :status, :work_type, :contribution_type, :ibm_status
  def status
    return @status || TypeStatus.find_by_TYPE_STATUS_and_SUB_TYPE(self.STATUS, 5)
  end
  
  def work_type
    return @work_type || TypeStatus.find_by_TYPE_STATUS_and_SUB_TYPE(self.TYPE_OF_WORK, 0)
  end
  
  def contribution_type
    return @contribution_type || TypeStatus.find_by_TYPE_STATUS_and_SUB_TYPE(self.CONTRIBUTION_TYPE, 19)
  end
  
  def ibm_status
    return @ibm_status || TypeStatus.find_by_TYPE_STATUS_and_SUB_TYPE(self.IBM_STATUS, 15)
  end
end
