import grails.converters.*
class ServicesController {

    def index = {
        def svc = new ServiceResponse(request:request.forwardURI,
            basePath:request.getServletPath())
        svc.setConnectorBase(request.getHeader('x-connector-base'))
        svc.buildFromConfig(grailsApplication.config.jangle.connector)
        render(contentType:"application/json",text:svc.toMap().encodeAsJSON())
    }

    def notFound = {
        response.status = 404 //Not Found
        render "${request.forwardURI} not found."
    }
}
