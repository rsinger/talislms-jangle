import org.codehaus.groovy.grails.commons.ConfigurationHolder
import groovyx.net.http.HTTPBuilder
import static groovyx.net.http.ContentType.JSON
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
}
