require 'marc'
class MARC::Record
  def to_xml
    marcxml = MARC::XMLWriter.encode(self, :include_namespace => true)
    marcxml.root.add_namespace('marc','http://www.loc.gov/MARC21/slim')    
    marcxml.root.delete_namespace
    marcxml.root.name = "marc:#{marcxml.root.name}"
    if marcxml.root.has_elements?
      add_prefix_to_tag(marcxml.root.elements)
    end
    marcxml    
  end
  
  def add_prefix_to_tag(elements)
    elements.each do | element |
      element.name = "marc:#{element.name}"
      if element.has_elements?
        add_prefix_to_tag(element.elements)
      end
    end
  end
end