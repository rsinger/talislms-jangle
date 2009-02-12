class CoreController {
    def coreService
    def retrieve = {
        def connector_response = coreService.getRequest(params.connector_name, params.path, params)
        def output = g.render(template:connector_response.type, model:['jangle':connector_response])
        for(xslt in connector_response.stylesheets) {
           output = coreService.applyXslt(output, xslt)
        }
        render(contentType:coreService.contentType(connector_response.type),text:output)
    }
}
