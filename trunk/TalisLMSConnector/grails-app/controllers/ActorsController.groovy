import grails.converters.*
class ActorsController {
    def requestService
    def feedService
    def index = {
        requestService.init()
        if(!session.user) {
          response.status = 401 //Not Found
          response.addHeader("WWW-Authenticate","Basic realm='Alto Jangle")
          render "Authorization Required."
          return
        } else {
            if(session.user_level == 1) {
                params.id = session.user
            }
        }
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) { params.offset = 0}
        def borrowers = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset.toInteger())
        if (!params.id) {
            borrowers = Borrower.list(max:grailsApplication.config.jangle.connector.maxResults,
                offset:params.offset.toInteger(), sort:"modified",order:"desc")
            feed.setTotalResults(Borrower.count())

        } else {
            borrowers = [Borrower.get(params.id)]
            feed.setTotalResults(borrowers.size)
        }

        feedService.buildFeed(feed,borrowers,params)

        render(contentType:'application/json',
            text:feed.toMap().encodeAsJSON())


    }
    def relationship = {
        requestService.init()
        if(!session.user) {
          response.status = 401 //Not Found
          response.addHeader("WWW-Authenticate","Basic realm='Alto Jangle")
          render "Authorization Required."
          return
        } else {
            if(session.user_level == 1) {
                params.id = session.user
            }
        }
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        feed.setOffset(params.offset.toInteger())
        def actors = Borrower.getAll(requestService.translateId(params.id))
        
        def ids = []
        actors.each {
            ids << it.id
        }

        def related = Loan.findItemsFromBorrowerIds(ids)


        feed.setTotalResults(related.size())
        feed.offset = params.offset.toInteger()
        if(related.size() > 0) {
            feedService.buildFeed(feed,related,params)
            render(contentType:'application/json',
                text:feed.toMap().encodeAsJSON())
        } else {

          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        }
    }

}
