xml.rdf :RDF, {"xmlns:rdf"=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'} do | rdf |
  rdf.rdf :Description, {"xmlns:dc"=>'http://purl.org/dc/elements/1.1/', 'rdf:about'=>entity_uri(entity.identifier)} do | desc |
    desc.dc :title, entity.title
    desc.dc :identifier, entity_uri(entity.identifier)
    desc.rdf :type,{"rdf:resource" => "http://purl.org/dc/dcmitype/Collection"}
  end
end