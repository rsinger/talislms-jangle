import grails.converters.*
class CollectionsController {
    def requestService
    def index = {
        requestService.connectorBase = request.getHeader('x-connector-base') ?
            request.getHeader('x-connector-base') : ''
        if(!params.offset) params.offset = 0
        def colls = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset)
        if(!params.id) {
            colls = WorkCollection.list(max:100,offset:params.offset)
            feed.setTotalResults(WorkCollection.count())
        } else {
            colls = [WorkCollection.get(params.id)]
            feed.setTotalResults(colls.size)
        }
        
        for(c in colls) {
            feed.addData(c.toMap())
        }
        render(contentType:requestService.contentType(request.getHeader('accept')),
            text:feed.toMap().encodeAsJSON())

    }
}
