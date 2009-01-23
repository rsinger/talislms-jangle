import grails.converters.*
class ItemsController {
    def requestService
    def index = {
        requestService.connectorBase = request.getHeader('x-connector-base') ?
            request.getHeader('x-connector-base') : ''
        if(!params.offset) params.offset = 0
        def items = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset)
        if(!params.id) {
            items = Item.list(max:100,offset:params.offset,sort:"modified",
            order:"desc")
            feed.setTotalResults(Item.count())
        } else {
            items = [Item.get(params.id)]
            feed.setTotalResults(items.size)
        }

        for(i in items) {
            feed.addData(i.toMap(params.format))
        }
        render(contentType:requestService.contentType(request.getHeader('accept')),
            text:feed.toMap().encodeAsJSON())

    }
}
