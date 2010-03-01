class Feed
  require 'uri'
  attr_reader :response_type, :formats, :alternate_formats, :time, :request, :entries
  attr_accessor :total_results, :stylesheets, :categories, :base, :entity, :offset
  def initialize(uri, time=Time.now)
    @request = uri
    @time = time
    @entries = []
    @formats = []
    @alternate_formats = {}
    @categories = []
  end
  
  def to_hash
    {:type=>'feed',
      :totalResults=>@total_results,
      :time=>@time.xmlschema,
      :offset=>@offset,
      :request=>@request,
      :alternate_formats=>@alternate_formats,
      :formats=>@formats,
      :categories=>@categories,
      :stylesheets=>@stylesheets,
      :data=>@entries}
  end
  
  def <<(data)
    #data[:id] = uri(data[:id])
    @entries << data
    @formats << data[:format]
    @categories = @categories + data[:categories] if data[:categories]
    @categories.uniq!
    @formats.uniq!
  end
  
  def uri(id)
    uri = @base.clone
    unless @base.match(/\/$/)
      uri << "/"
    end
    uri << "#{@entity}/#{id}"
    uri
  end
  def alt_fmt_uri(uri, format)
    u = URI.parse(@request)
    u.query ||=""
    if u.query.match(/format=/)
      u.query.sub!(/format=[^&\b]*/,"format=#{format}")
    else
      u.query << "&" if u.query && !u.query.nil?
      u.query << "format=#{format}" 
    end
    u.to_s  
  end
  
  def set_stylesheets(config, format)
    begin
      ent = config['record_types'][format]['stylesheets']['feed']['entities']
      if ent.index(@entity)
        @stylesheets ||=[] << config['record_types'][format]['stylesheets']['feed']['uri']
      end
    rescue NoMethodError
    end
  end
  
  def set_alternate_formats(config)
    config['entities'][@entity]['record_types'].each do |key|
      fmt = config['record_types'][key]
      unless @formats.index(fmt['uri'])
        @alternate_formats[fmt['uri']] = alt_fmt_uri(@request, key)
      end
    end
  end
end
  