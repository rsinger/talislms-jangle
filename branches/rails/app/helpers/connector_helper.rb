module ConnectorHelper
  def get_feed_stylesheets
    begin
      if AppConfig.connector['record_types'][@format]['stylesheets']['feed']['entities'].index(params[:entity])
        xslt = AppConfig.connector['record_types'][@format]['stylesheets']['feed']['uri']
        return [xslt]
      end
    rescue NoMethodError
    end
  end
end
