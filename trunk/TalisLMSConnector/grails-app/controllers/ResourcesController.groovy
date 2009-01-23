import grails.converters.*
class ResourcesController {
    def resourceService
    def requestService
    def index = {
        requestService.connectorBase = request.getHeader('x-connector-base') ?
            request.getHeader('x-connector-base') : ''
        if(!params.offset) params.offset = 0
        def works = []
        def feed = new FeedResponse(request:request.forwardURI)
        feed.setOffset(params.offset)
        if(!params.id) {
            works = WorkMetadata.list(max:50,sort:"modified",order:"desc",
                offset:params.offset)
            feed.setTotalResults(Work.count())
        } else {
            works = WorkMetadata.getAll(requestService.translateId(params.id))
            feed.setTotalResults(works.size)
        }
        
        Item.itemCheckFromWorks(works)
        Title.getTitlesForWorks(works)
        for(w in works) {
            feed.addData(w.toMap(params.format))
        }
        if(!params.format) params.format = 'marcxml'
        
             
        if(resourceService.addStylesheet(params.format)) {
            feed.addStylesheet(resourceService.addStylesheet(params.format))
        }

        if(params.id && works.size() < 1) {
          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        } else {
            render(contentType:requestService.contentType(request.getHeader('accept')),
                text:feed.toMap().encodeAsJSON())
        }

    }

    def relationship = {
        requestService.connectorBase = request.getHeader('x-connector-base') ?
            request.getHeader('x-connector-base') : ''
        def feed = new FeedResponse(request:request.forwardURI)
        if(!params.offset) params.offset = 0
        def works = WorkMetadata.getAll(requestService.translateId(params.id))
        def related = []
        works.each {
            if(params.relationship == "items") {
                related = it.getItems(params.offset,params.format)
            } else {
                related = it.getCollections(params.offset,params.format)
            }
        }
        feed.setTotalResults(related.size())
        feed.offset = params.offset
        for(r in related) {
            feed.addData(r)
        }
        if(related.size() > 0) {
            render(contentType:requestService.contentType(request.getHeader('accept')),
                text:feed.toMap().encodeAsJSON())
        } else {

          response.status = 404 //Not Found
          render "${request.forwardURI} not found."
        }


    }
}
