xml.diagnostics(:xmlns=>"http://www.loc.gov/zing/srw/diagnostic/") do |diagnostics|
  diagnostics.diagnostic do |diagnostic|
    diagnostic.uri "info:srw/diagnostic/1/7"
    diagnostic.message "Mandatory parameter not supplied:  #{message}"
  end
end
