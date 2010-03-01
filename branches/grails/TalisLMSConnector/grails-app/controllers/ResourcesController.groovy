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
            if (feed.offset > grailsApplication.config.jangle.connector.maxResults) {
                def worklist = WorkMetadata.search("*:*", sort:"modified", order:"desc",
                    max:grailsApplication.config.jangle.connector.maxResults,
                    offset:params.offset.toInteger())
                    //def ids = []
                    //worklist.results.each {
                    //    ids << it.id
                    //}
                    //works = WorkMetadata.getAll(ids)
                    works = worklist.results
                    feed.setTotalResults(worklist.total)
            } else {
                works = WorkMetadata.list(max:grailsApplication.config.jangle.connector.maxResults,
                        offset:feed.offset,sort:"modified",order:"desc")
                feed.setTotalResults(WorkMetadata.count())
            }
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
            render(contentType:'application/json',
                text:feed.toMap().encodeAsJSON())
        }
        
        if (feed.offset < grailsApplication.config.jangle.connector.maxResults) {
            def updates = WorkMetadata.syncIndex()            
        }

    }

    def relationship = {
        requestService.init()
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        feed.setOffset(params.offset.toInteger())
        def works = WorkMetadata.getAll(requestService.translateId(params.id))
        def related = []
        def ids = []
        works.each {
            ids << it.id
        }

        if(params.relationship == "items") {
            related = Item.findAllByWorkIdInList(ids, 
                [max:grailsApplication.config.jangle.connector.maxResults,
                offset:feed.offset,sort:"modified",order:"desc"])
        } else {
            related = WorkCollection.getAllByWorkIds(ids, feed.offset,
                grailsApplication.config.jangle.connector.maxResults)
        }
        related.each {
            it.setVia('resources', ids)
        }
                
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

    def filter = {
        feedService.setConnectorBase(request.getHeader('x-connector-base'))
        if(!params.offset) params.offset = 0
        def works = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset.toInteger())
        if(params.filter == 'opac') {
            if (feed.offset > grailsApplication.config.jangle.connector.maxResults) {
                def worklist = WorkMetadata.search("opacSuppress:F AND indexSuppress:F", sort:"modified", order:"desc",
                    max:grailsApplication.config.jangle.connector.maxResults,
                    offset:params.offset.toInteger())
                    //def ids = []
                    //worklist.results.each {
                    //    ids << it.id
                    //}
                    //works = WorkMetadata.getAll(ids)
                    works = worklist.results
                    feed.setTotalResults(worklist.total)
            } else {
                def c = WorkMetadata.createCriteria()
                works = c.list(max:grailsApplication.config.jangle.connector.maxResults,
                        offset:feed.offset,sort:"modified",order:"desc") {
                        eq('opacSuppress','F')
                        }
                c = WorkMetadata.createCriteria()
                def count = c.get {
                    projections {count('id')}
                    eq('opacSuppress','F')            
                    and {
                        eq('indexSuppress','F')
                    }    
                }
                feed.setTotalResults(count)
            }            

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
        if (feed.offset < grailsApplication.config.jangle.connector.maxResults) {
            def updates = WorkMetadata.syncIndex()
            print updates.size
        }        
        

    }

    def status = {
        [workSearch: WorkMetadata.countHits('*:*'),
        workCount: WorkMetadata.count()]
    }
}
