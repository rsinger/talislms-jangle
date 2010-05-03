# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def uri_from_format(format_key)
    AppConfig.connector['record_types'][format_key]['uri']
  end
  def determine_partial(format)
    AppConfig.connector['entities'][params[:entity]]['record_types'][format]
  end
  def entity_uri(id, entity=params[:entity]) 
    uri = "#{@connector_base}/#{entity}/#{id}"
    uri
  end
  def alt_fmt_uri(uri, format)
    u = URI.parse(uri)
    u.query ||=""
    if u.query.match(/format=/)
      u.query.sub!(/format=[^&\b]*/,"format=#{format}")
    else
      u.query << "&" if u.query && !u.query.empty?
      u.query << "format=#{format}" 
    end
    u.to_s  
  end  
  def get_alternate_formats(format, uri)
    alternate_formats = {}
    AppConfig.connector['entities'][params[:entity]]['record_types'].keys.each do |key|
      next if key == format
      fmt = AppConfig.connector['record_types'][key]
      alternate_formats[fmt['uri']] = alt_fmt_uri(uri, key)
    end
    alternate_formats
  end 
  
  def set_relationships(entity)
    rels = {}
    if entity.relationships
      entity.relationships.each do | rel |
        rels["http://jangle.org/vocab/Entities##{rel.capitalize}"] = entity_uri(entity.identifier)+"/#{rel}s/"
      end
    end
    rels
  end
end
