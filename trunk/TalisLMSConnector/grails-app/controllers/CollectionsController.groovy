import grails.converters.*
class CollectionsController {
    def requestService
    def feedService
    def index = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) params.offset = 0
        def colls = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset.toInteger())
        if(!params.id) {
            colls = WorkCollection.list(max:grailsApplication.config.jangle.connector.global_options.maximum_results,offset:params.offset.toInteger())
            feed.setTotalResults(WorkCollection.count())
        } else {
            colls = [WorkCollection.get(params.id)]
            feed.setTotalResults(colls.size)
        }
        feedService.buildFeed(feed,colls,params)
        render(contentType:requestService.contentType(request.getHeader('accept')),
            text:feed.toMap().encodeAsJSON())

    }
    def relationship = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        def coll = WorkCollection.getAll(requestService.translateId(params.id))
        def related = []
        coll.each {
            related = it.getWorks(params.offset.toInteger())
        }

        feed.setTotalResults(related.size())
        feed.offset = params.offset.toInteger()

        if(related.size() > 0) {
            feedService.buildFeed(feed,related,params)
            render(contentType:requestService.contentType(request.getHeader('accept')),
                text:feed.toMap().encodeAsJSON())
        } else {

          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        }


    }
}
