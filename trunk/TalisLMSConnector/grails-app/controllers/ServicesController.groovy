import grails.converters.*
class ServicesController {

    def index = {
        def svc = new ServiceResponse(request:request.forwardURI,
            basePath:request.getServletPath())
        render(contentType:"application/json",text:svc.toMap().encodeAsJSON())
    }
}
