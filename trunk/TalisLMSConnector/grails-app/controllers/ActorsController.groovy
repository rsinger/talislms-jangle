import grails.converters.*
class ActorsController {
    def requestService
    def index = {
        requestService.connectorBase = request.getHeader('x-connector-base') ?
            request.getHeader('x-connector-base') : ''
        if(!params.offset) { params.offset = 0}
        def borrowers = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset)
        if (!params.id) {
            borrowers = Borrower.list(max:100, offset:params.offset, sort:"modified",order:"desc")
            feed.setTotalResults(Borrower.count())

        } else {
            borrowers = [Borrower.get(params.id)]
            feed.setTotalResults(borrowers.size)
        }
        for(b in borrowers) { feed.addData(b.toMap()) }

        render(contentType:requestService.contentType(request.getHeader('accept')),
            text:feed.toMap().encodeAsJSON())


    }
}
