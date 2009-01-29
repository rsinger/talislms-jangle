class RequestService {
    def connectorBase
    def dataSource
    def entityBuilder
    static scope = "request"
    def translateId(id) {        
        if(id =~ /^\d*$/) {
            return [id]
        }
        def ids = []
        if(id =~ /^(\d+[,;]?)*$/) {
            def idList = id.split(/[,;]/)
            idList.each {
                ids << it.toInteger()
            }
        } else {
            id.split(/[,;]/).each {
                if(it =~ /^\d*$/) {
                    ids << it.toInteger()
                } else {
                    def rng = it.split(/-/)
                    (rng[0].toInteger()..rng[1].toInteger()).each {
                        ids << it.toInteger()
                    }
                }
            }
        }
        return ids

    }

    def setConnectorBase(header) {
        connectorBase = header ? header : ''

    }

    def getConnectorBase() {
        connectorBase
    }
    
    def contentType(type) {

        def contentType
        switch(type) {
            case 'application/json':
                contentType = 'application/json'
                break
            default:
                contentType = 'text/plain'
        }
        contentType

    }

    def init() {
        entityBuilder = new EntityBuilder(dataSource:dataSource)
        
    }

    def setResourceAttributes(works) {
        Item.itemCheckFromWorks(works)
        Title.getTitlesForWorks(works)
        entityBuilder.setEntityAttributes(works)
    }

}
