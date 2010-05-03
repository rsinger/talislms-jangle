xml.alto :Work, :id=>entity.id do |work|
  work.alto :"talis-control-number", entity.TALIS_CONTROL_NUMBER
  work.alto :"last-modified", entity.MODIFIED_DATE
  work.alto :record do |rec|
    xml << entity.to_marcxml.to_s
  end
  work.alto :suppress, :"from-opac"=>entity.SUPPRESS_FROM_OPAC, :"from-index"=>entity.SUPPRESS_FROM_INDEX
  work.alto :meta, :type=>entity.META_TYPE, :encoding=>entity.META_ENCODING
  work.alto :test, entity.TEST
  work.alto :"to-convert", entity.TOCONVERT
  if entity.work
    if status = entity.work.status
      xml.alto :status, status.NAME, :code=>status.CODE
    end
    if work_type = entity.work.work_type
      xml.alto :type, work_type.NAME, :code=>work_type.CODE 
    end
    if ibm_status = entity.work.ibm_status
      work.alto :"ibm-status", ibm_status.NAME, :code=>ibm_status.CODE
    end
    if contrib_type = entity.work.contribution_type
      work.alto :"contribution-type", contrib_type.NAME, :code=>contrib_type.CODE
    end
    work.alto :monograph, entity.work.MONOGRAPH 
    work.alto :"author-display", entity.work.AUTHOR_DISPLAY
    work.alto :"author-sort", entity.work.AUTHOR_FILING
    work.alto :title do |title|
      if entity.work.TITLE_DISPLAY
        work.alto :display, entity.work.TITLE_DISPLAY.sub(/\.\s\-\s/,"")
      end
      if entity.work.TITLE_FILING_OFFSET && entity.work.TITLE_FILING_OFFSET.to_i > 4
        work.alto :"sort", entity.work.TITLE_DISPLAY[entity.work.TITLE_FILING_OFFSET.to_i..-1]
      end
    end
    work.alto :"classification-display", entity.work.CLASS_DISPLAY
  end
end