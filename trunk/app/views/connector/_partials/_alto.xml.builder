xml.alto :TalisAlto, "xmlns:alto"=>"http://schema.talis.com/alto/jangle/v1/" do |alto|
  xml << render(:partial=>"/connector/_partials/alto/#{entity.class.name.downcase}.xml.builder", :locals=>{:entity=>entity}) 
end