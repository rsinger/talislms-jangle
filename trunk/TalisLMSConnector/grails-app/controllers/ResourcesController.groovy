import grails.converters.*
class ResourcesController {
    def resourceService
    def requestService
    def feedService
    def index = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) params.offset = 0
        def works = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset)
        if(!params.id) {
            works = WorkMetadata.list(max:grailsApplication.config.jangle.connector.global_options.maximum_results,sort:"modified",order:"desc",
                offset:params.offset)
            feed.setTotalResults(Work.count())
        } else {
            works = WorkMetadata.getAll(requestService.translateId(params.id))
            feed.setTotalResults(works.size)
        }
        feedService.buildFeed(feed,works,params)
//        requestService.setResourceAttributes(works)


        if(params.id && works.size() < 1) {
          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        } else {
            render(contentType:requestService.contentType(request.getHeader('accept')),
                text:feed.toMap().encodeAsJSON())
        }

    }

    def relationship = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        def works = WorkMetadata.getAll(requestService.translateId(params.id))
        def related = []
        works.each {
            if(params.relationship == "items") {
                related = it.getItems(params.offset)                
            } else {
                related = it.getCollections(params.offset)
            }
        }

        feed.setTotalResults(related.size())
        feed.offset = params.offset
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
