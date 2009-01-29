import grails.converters.*
class ItemsController {
    def requestService
    def feedService
    def index = {
        requestService.init()
        requestService.entityBuilder.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) params.offset = 0
        def items = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset)

//        
        if(!params.id) {
            items = Item.list(max:grailsApplication.config.jangle.connector.global_options.maximum_results,offset:params.offset,sort:"created",
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
}
