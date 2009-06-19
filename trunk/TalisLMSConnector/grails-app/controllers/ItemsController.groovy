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
        if(!params.id) {
            if (feed.offset > grailsApplication.config.jangle.connector.maxResults) {
                def itemlist = Item.search("*:*", sort:"modified", order:"desc",
                    max:grailsApplication.config.jangle.connector.maxResults,
                    offset:params.offset.toInteger())

                    items = itemlist.results
                    feed.setTotalResults(itemlist.total)            
            } else {
                items = Item.list(max:grailsApplication.config.jangle.connector.maxResults,offset:params.offset.toInteger(),sort:"created",
                order:"desc")
                feed.setTotalResults(Item.count())
            }
        } else {
            items = [Item.get(params.id)]
            feed.setTotalResults(items.size)
        }
        feedService.buildFeed(feed,items,params)

        render(contentType:'application/json',
            text:feed.toMap().encodeAsJSON())

    }

    def relationship = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        def items = Item.getAll(requestService.translateId(params.id))
        def related = [:]
        def currWork
        items.each {
            currWork = it.getWork()
            if(!related[currWork.id]) {
                currWork.via['items'] = [it.id]
                related[currWork.id] = currWork
            } else {
                related[currWork.id].via['items'] << it.id
            }

        }

        feed.setTotalResults(related.size())
        feed.offset = params.offset.toInteger()
        if(related.size() > 0) {
            feedService.buildFeed(feed,related.values().toList(),params)
            render(contentType:'application/json',
                text:feed.toMap().encodeAsJSON())
        } else {

          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        }


    }
}
