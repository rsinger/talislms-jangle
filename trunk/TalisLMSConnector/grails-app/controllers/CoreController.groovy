class CoreController {
    def coreService
    def retrieve = {
        def connector_response = coreService.getRequest(params.connector_name, params.path, params)
        if(connector_response.status == 200) {
            def output = g.render(template:connector_response.contents.type, model:['jangle':connector_response.contents])
            for(xslt in connector_response.contents.stylesheets) {
                output = coreService.applyXslt(output, xslt)
            }
            render(contentType:coreService.contentType(connector_response.contents.type),text:output)
        }else{
            response.status = connector_response.status
            render connector_response.message
        }
    }

    def services = {
        if(!coreService.services) {coreService.gatherServices()}
        println coreService.services
        render(contentType:'application/atomsvc+xml',model:['jangle':coreService.services],view:'_service')
    }
}