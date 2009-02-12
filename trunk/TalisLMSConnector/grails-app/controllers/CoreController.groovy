class CoreController {
    def coreService
    def retrieve = {
        def connector_response = coreService.getRequest(params.connector_name, params.path, params)
        if(connector_response.status == 200) {
            def output = g.render(template:connector_response.content.type, model:['jangle':connector_response.content])
            for(xslt in connector_response.content.stylesheets) {
                output = coreService.applyXslt(output, xslt)
            }
            render(contentType:coreService.contentType(connector_response.content.type),text:output)
        }else{
            response.status = connector_response.status
            render connector_response.message
        }
    }

    def renderHttpError = {
        response.status = coreService.client_http_status
        render coreService.client_http_message
    }
}

class ConnectorClientException extends Exception {}


