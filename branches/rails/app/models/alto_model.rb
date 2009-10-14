class AltoModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection("alto_#{ RAILS_ENV }")
  #extend(JdbcSpec::Sybase)
  attr_reader :uri
  def set_uri(base, path)
    @uri = "#{base}/#{path}/#{self.id}"
    puts @uri
  end
  
  def delete
    raise ActiveRecord::ReadOnlyRecord
  end
  
  def destroy()
    raise ActiveRecord::ReadOnlyRecord
  end
  
  def save()
    raise ActiveRecord::ReadOnlyRecord
  end

  def save!()
    raise ActiveRecord::ReadOnlyRecord
  end  
end