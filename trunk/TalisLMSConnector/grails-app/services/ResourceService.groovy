class ResourceService {

    def String addStylesheet(String fmt) {
        def xslMap = ["mods":"http://jangle.googlecode.com/svn/trunk/xsl/AtomMARC21slim2MODS3-2.xsl",
        "dc":"http://jangle.googlecode.com/svn/trunk/xsl/AtomMARC21slim2RDFDC.xsl",
        "oai_dc":"http://jangle.googlecode.com/svn/trunk/xsl/AtomMARC21slim2OAIDC.xsl"]
        def xsl = null
        xslMap.each { format,uri ->
            if(format == fmt) {                
                xsl = uri
            }
        }
        return xsl
    }


}
