import org.codehaus.groovy.grails.commons.ConfigurationHolder
import groovyx.net.http.HTTPBuilder
import static groovyx.net.http.ContentType.JSON
import javax.xml.transform.TransformerFactory
import javax.xml.transform.stream.StreamResult
import javax.xml.transform.stream.StreamSource

class CoreService {
    def config = ConfigurationHolder.config.jangle.core
    def services
    def stylesheets = [:]
    def entityMap = ["actors":"Actor","collections":"Collection","items":"Item","resources":"Resource"]
    
    boolean transactional = true
    def getRequest(connector, resource, params) {
        if(!services) {gatherServices()}
        def connector_response = new ConnectorResponse()
        def connector_uri
        def path = ''
        try {
            if (resource != 'services' && resource != 'services/') {
                path = services[connector].entities[entityMap[resource.split("/")[0]]].path
            } else {
                path = '/services/'
            }
            connector_uri = new URI(config['connectors'][connector]['url']+path)
            
        } catch(e) {
            connector_response.status = 404
            connector_response.message = "Connector not found:  ${connector}"
            return connector_response
        }
        //        
        def http = new HTTPBuilder(connector_uri.scheme+'://'+connector_uri.getAuthority())
        def query_vars = [:]
        params.each {key, val->
            if(!(key =~ /^(connector_name|path|controller|action)$/)) {
                query_vars[key] = val
            }
        }
        try {
            connector_response.contents = http.get(path:connector_uri.path,contentType:JSON, params:query_vars,headers:["X-CONNECTOR-BASE":config['base_uri']+connector])
            
        } catch(e) {
            switch(e.getClass()) {
                case org.apache.http.client.HttpResponseException:
                connector_response.status = e.getStatusCode()
                connector_response.message = e.getMessage()
                break
                default:
                connector_response.status = 500
                connector_response.message = 'Internal Server Error'
            }
            return connector_response

        }

        connector_response.status = 200
        connector_response.message = "OK"
        if(!connector_response.contents.title) { 
            connector_response.contents['title'] = connector
        }
        return connector_response
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
            contentType = 'application/atomsvc+xml'
            break
            case 'explain':
            contentType = 'application/opensearchdescription+xml'
        }
        return contentType
    }

    def applyXslt(doc, xsltUri) {        
        def xslt = new URL(xsltUri)
        def output = new StringWriter()
        def factory = TransformerFactory.newInstance()
        def transformer = factory.newTransformer(new StreamSource(new StringReader(xslt.text)))
        transformer.transform(new StreamSource(new StringReader(doc)), new StreamResult(output))        
        return output.toString()
    }

    def gatherServices() {
        services = [:]        
        config.connectors.each {name,conf->
            def uri = new URI(conf.url+"/services")
            def http = new HTTPBuilder(uri.scheme+'://'+uri.getAuthority())
            services[name] = http.get(path:uri.path,contentType:JSON, headers:["X-CONNECTOR-BASE":config.base_uri+name])
            services[name].entities.each {entity, vals ->
                vals['uri'] = config.base_uri + name + "/" + entity.toLowerCase()+'s'
            }
        }
    }
}
