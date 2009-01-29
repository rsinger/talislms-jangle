import grails.converters.*
class ItemsController {
    def requestService
    def feedService
    def index = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) params.offset = 0
        def items = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset.toInteger())

//        
        if(!params.id) {
            items = Item.list(max:grailsApplication.config.jangle.connector.global_options.maximum_results,offset:params.offset.toInteger(),sort:"created",
            order:"desc")
            feed.setTotalResults(Item.count())
        } else {
            items = [Item.get(params.id)]
            feed.setTotalResults(items.size)
        }
        feedService.buildFeed(feed,items,params)

        render(contentType:requestService.contentType(request.getHeader('accept')),
            text:feed.toMap().encodeAsJSON())

    }

    def relationship = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        def items = Item.getAll(requestService.translateId(params.id))
        def related = []
        items.each {
            related = [it.getWork()]
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
