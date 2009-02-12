import org.codehaus.groovy.grails.commons.ConfigurationHolder
import groovyx.net.http.HTTPBuilder
import static groovyx.net.http.ContentType.JSON
import javax.xml.transform.TransformerFactory
import javax.xml.transform.stream.StreamResult
import javax.xml.transform.stream.StreamSource
class CoreService {
    def config = ConfigurationHolder.config.jangle.core
    boolean transactional = true

    def getRequest(connector, resource, params) {
        def connector_uri = new URI(config['connectors'][connector]['url']+resource)
        
        def http = new HTTPBuilder(connector_uri.scheme+'://'+connector_uri.getAuthority())        
        def query_vars = [:]
        params.each {key, val->
            if(!(key =~ /^(connector_name|path|controller|action)$/)) {
                query_vars[key] = val
            }
        }        
        def response = http.get(path:connector_uri.path,contentType:JSON, params:query_vars,headers:["X-CONNECTOR-BASE":config['base_uri']+connector])
        if(!response.title) { response.title = connector}
        return response
    }

    def contentType(responseType) {
        def contentType = ''
        switch(responseType) {
            case 'feed':
            contentType = 'application/atom+xml'
            break
            case 'search':
            contentType = 'application/atom+xml'
            break
            case 'service':
            contentType = 'application/atomservice+xml'
            break
            case 'explain':
            contentType = 'application/opensearchdescription+xml'
        }
        return contentType
    }

    def applyXslt(doc, xsltUri) {
        println doc.getClass()
        def xslt = new URL(xsltUri)
        def output = new StringWriter()
        def factory = TransformerFactory.newInstance()
        def transformer = factory.newTransformer(new StreamSource(new StringReader(xslt.text)))
        transformer.transform(new StreamSource(new StringReader(doc)), new StreamResult(output))
        println output
        return output.toString()
    }
}
