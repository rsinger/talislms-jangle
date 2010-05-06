xml.alto :Work, :id=>entity.id do |work|
  work.alto :talisControlNumber, entity.TALIS_CONTROL_NUMBER
  work.alto :lastModified, entity.MODIFIED_DATE
  work.alto :record do |rec|
    xml << entity.to_marcxml.to_s
  end
  work.alto :suppress, :fromOpac=>entity.SUPPRESS_FROM_OPAC, :fromIndex=>entity.SUPPRESS_FROM_INDEX
  work.alto :meta, :type=>entity.META_TYPE, :encoding=>entity.META_ENCODING
  work.alto :test, entity.TEST
  work.alto :toConvert, entity.TOCONVERT
  if entity.work
    if status = entity.work.status
      xml.alto :status, status.NAME, :code=>status.CODE
    end
    if work_type = entity.work.work_type
      xml.alto :type, work_type.NAME, :code=>work_type.CODE 
    end
    if ibm_status = entity.work.ibm_status
      work.alto :ibmStatus, ibm_status.NAME, :code=>ibm_status.CODE
    end
    if contrib_type = entity.work.contribution_type
      work.alto :contributionType, contrib_type.NAME, :code=>contrib_type.CODE
    end
    work.alto :monograph, entity.work.MONOGRAPH 
    work.alto :authorDisplay, entity.work.AUTHOR_DISPLAY
    work.alto :authorSort, entity.work.AUTHOR_FILING
    work.alto :title do |title|
      if entity.work.TITLE_DISPLAY
        work.alto :display, entity.work.TITLE_DISPLAY.sub(/\.\s\-\s/,"")
      end
      if entity.work.TITLE_FILING_OFFSET && entity.work.TITLE_FILING_OFFSET.to_i > 4
        work.alto :"sort", entity.work.TITLE_DISPLAY[entity.work.TITLE_FILING_OFFSET.to_i..-1]
      end
    end
    work.alto :classificationDisplay", entity.work.CLASS_DISPLAY
  end
end