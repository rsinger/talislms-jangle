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
    def relationship = {
        requestService.connectorBase = request.getHeader('x-connector-base') ?
            request.getHeader('x-connector-base') : ''
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        def coll = WorkMetadata.getAll(requestService.translateId(params.id))
        def related = []
        coll.each {
            related = it.getWorks(params.offset,params.format)
        }
        feed.setTotalResults(related.size())
        feed.offset = params.offset
        for(r in related) {
            feed.addData(r)
        }
        if(related.size() > 0) {
            render(contentType:requestService.contentType(request.getHeader('accept')),
                text:feed.toMap().encodeAsJSON())
        } else {

          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        }


    }
}
