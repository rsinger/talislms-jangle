import grails.converters.*
class ServicesController {

    def index = {
        def svc = new ServiceResponse(request:request.forwardURI,
            basePath:request.getServletPath())
        svc.buildFromConfig(grailsApplication.config.jangle.connector)
        render(contentType:"application/json",text:svc.toMap().encodeAsJSON())
    }
}
