xml.diagnostics(:xmlns=>"http://www.loc.gov/zing/srw/diagnostic/") do |diagnostics|
  diagnostics.diagnostic do |diagnostic|
    diagnostic.uri "info:srw/diagnostic/1/16"
    diagnostic.message "Unsupported index:  #{message}"
  end
end
