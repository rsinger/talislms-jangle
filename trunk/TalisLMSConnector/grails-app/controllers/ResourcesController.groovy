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
        feed.setOffset(params.offset.toInteger())
        if(!params.id) {
            works = WorkMetadata.list(max:grailsApplication.config.jangle.connector.global_options.maximum_results,sort:"modified",order:"desc",
                offset:params.offset.toInteger())
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
                related = it.getItems(params.offset.toInteger())
            } else {
                related = it.getCollections(params.offset.toInteger())
            }
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

    def filter = {
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) params.offset = 0
        def works = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset.toInteger())
        if(params.filter == 'opac') {

            def c = WorkMetadata.createCriteria()
            works = c.list(max:grailsApplication.config.jangle.connector.global_options.maximum_results,
                    offset:feed.offset,sort:"modified",order:"desc") {
                    eq('opacSuppress','F')
                    }
            c = WorkMetadata.createCriteria()
            def count = c.get {
                projections {count('id')}
                eq('opacSuppress','F')                
            }
            feed.setTotalResults(count)

            feedService.buildFeed(feed,works,params)
//        requestService.setResourceAttributes(works)
        } else {
          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        }

        if(params.id && works.size() < 1) {
          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        } else {
            render(contentType:requestService.contentType(request.getHeader('accept')),
                text:feed.toMap().encodeAsJSON())
        }
        

    }
}
