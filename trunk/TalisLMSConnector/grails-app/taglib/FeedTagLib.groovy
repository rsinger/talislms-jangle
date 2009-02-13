import groovyx.net.http.URIBuilder
import javax.xml.transform.TransformerFactory
import javax.xml.transform.stream.StreamResult
import javax.xml.transform.stream.StreamSource

class FeedTagLib {
    static namespace = "jfeed"
    def pagelink = {attrs, body ->
        def uri = new URIBuilder(attrs.uri)
        if(uri.hasQueryParam('offset')) {
            uri.removeQueryParam('offset')
        }

        if(attrs.offset) {
            uri.addQueryParam('offset',attrs.offset)
        }
        out << body() << "<link rel='${attrs.rel}' href='${uri.toString()}' type='application/atom+xml' />"
    }

    def applyxslt = {attrs, body ->
        def xslt = new URL(attrs.xslt)
        def output = new StringWriter()
        def factory = TransformerFactory.newInstance()
        def transformer = factory.newTransformer(new StreamSource(new StringReader(xslt.text)))
        transformer.transform(new StreamSource(new StringReader(attrs.content)), new StreamResult(output))
        out << body() << output

    }

    def categoryBuilder = {attrs, body ->
        def tag = "<atom:category term='${attrs.category}'"
        if(attrs.categories && attrs.categories[attrs.category]) {
            if(attrs.categories[attrs.category].scheme) {
                tag = "${tag} scheme='${attrs.categories[attrs.category].scheme}'"
            }
            if(attrs.categories[attrs.category].label) {
                tag = "${tag} label='${attrs.categories[attrs.category].label}'"
            }

        }
        out << tag + " />"

    }
    private static final String AMP = "&amp;"
    private static final String LT = "&lt;"
    private static final String GT = "&gt;"
    private static final String QUOTE = "&quot;"

/** * Escape HTML entities within the body. */ 
    def esc = { attrs, body -> def text = ''


        out << escapeEntities(body());
    }

/** * Return the given string with all HTML entities escaped into their * HTML equivalent. * * @param text String containing unsafe characters. * @return <var>text</var> with characters turned into HTML entities. */ 
    public static String escapeEntities(String text) { 
        if (text == null) text = "" 
        String trim = text.trim() 
        char[] c = trim.toCharArray()

        StringBuffer buffer = new StringBuffer() 
        def i = -1; 
        while (++i < c.length) { 
            if (c[i]=='&') buffer.append(AMP) 
            else if (c[i]=='<') buffer.append(LT) 
            else if(c[i]=='>') buffer.append(GT) 
            else if(c[i]=='"') buffer.append(QUOTE) 
            else buffer.append(c[i]) 
        } 
        return buffer.toString() 
    }

}
