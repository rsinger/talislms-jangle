class Title < AltoModel
  set_table_name 'TITLE'
  set_primary_key 'TITLE_ID'
  belongs_to :work_meta, :foreign_key=>'WORK_ID'
  belongs_to :collection, :foreign_key=>'COLLECTION_ID'
  
  # FIXME: TITLE joins COLLECTION and WORK, however an index appears to be missing on COLLECTION_ID
end
