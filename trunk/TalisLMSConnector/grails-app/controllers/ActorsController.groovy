import grails.converters.*
class ActorsController {
    def requestService
    def feedService
    def index = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) { params.offset = 0}
        def borrowers = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset)
        if (!params.id) {
            borrowers = Borrower.list(max:grailsApplication.config.jangle.connector.global_options.maximum_results,
                offset:params.offset, sort:"modified",order:"desc")
            feed.setTotalResults(Borrower.count())

        } else {
            borrowers = [Borrower.get(params.id)]
            feed.setTotalResults(borrowers.size)
        }

        feedService.buildFeed(feed,borrowers,params)

        render(contentType:requestService.contentType(request.getHeader('accept')),
            text:feed.toMap().encodeAsJSON())


    }

}
