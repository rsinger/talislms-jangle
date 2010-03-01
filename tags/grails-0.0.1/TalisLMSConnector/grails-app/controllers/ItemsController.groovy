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

        if (feed.offset < grailsApplication.config.jangle.connector.maxResults) {
            def updates = Item.syncIndex()
        }
    }

    def relationship = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        def items = Item.getAll(requestService.translateId(params.id))
        def related = [:]
        
        if(params.relationship == 'actors') {
            if(!session.user) {
                response.status = 401 //Not Found
                response.addHeader("WWW-Authenticate","Basic realm='Alto Jangle")
                render "Authorization Required."
                return
            } else {
                def actorIds = []
                Loan.findCurrentLoansFromItemList(items)
                items.each {
                    if(session.user_level == 1 && it.borrowerId != session.user) {
                    } else {
                        if(!actorIds.contains(it.borrowerId)) { actorIds << it.borrowerId }
                    }
                }
                println actorIds
                if(actorIds.size() > 0) {
                    def actors = Borrower.getAll(actorIds)
                    actors.each {
                        println it.id
                        related[it.id] = it
                        related[it.id].via['items'] = []
                    }
                    items.each {
                        related[it.borrowerId].via['items'] << it.id
                    }
                }
            }
        } else {
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
