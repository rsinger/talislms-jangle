import java.sql.Timestamp
import groovy.xml.MarkupBuilder
import java.text.SimpleDateFormat
class Item {
    String fauxId
    String barcode
    Integer status_id
    Long workId
    String site
    Timestamp modified
    Timestamp created
    String uri
    String workUri
    Boolean available
    String statusMessage
    Map location
    Timestamp dateAvailable
    Long borrowerId
    Integer classId
    Boolean onLoan = false
    String suffix
    Map via = [:]
    static transients = ['uri','workUri','available', 'location','statusMessage',
    'dateAvailable', 'borrowerId', 'onLoan', 'via', 'fauxId']
    static searchable = true
    static mapping = {
       table 'ITEM'
       version false       
        columns {
            id column: 'ITEM_ID'
            barcode column: 'BARCODE'
            status_id column: 'STATUS_ID'
            workId column: 'WORK_ID'
            site column: 'ACTIVE_SITE_ID'
            modified column: 'EDIT_DATE'
            created column: 'CREATE_DATE'
            classId column: 'CLASS_ID'
            suffix column: 'SUFFIX'
        }

    }

    static constraints = {
        barcode(nullable:true)
        modified(nullable:true)
        classId(nullable:true)
        suffix(nullable:true)
    }

    def afterLoad = {
        fauxId = 'i-'+id
    }

    static def itemCheckFromWorks(worksList) {
        def workIds = []
        worksList.each {
            workIds << it.id            
        }
        def workIdList = executeQuery("SELECT DISTINCT i.workId FROM Item i WHERE i.workId IN (:idList)",
            [idList:workIds])
        for(work in worksList) {
            if(workIdList.contains(work.id)) {
                work.setHasItems(true)
            } else {
                work.setHasItems(false)
            }
        }

    }
    def setEntityUri(connectorBase) {
        if(!connectorBase) { connectorBase = ''}
        this.uri = "${connectorBase}/items/${fauxId}"
        this.workUri = "${connectorBase}/resources/${workId}"
    }
    def toMap() {
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        
        is_available()
        
        if(!modified) { modified = created }	
        def itemMap = ["id":uri,
            "updated":dateFormatter.format(modified),
            "created":dateFormatter.format(created)]
        
        def relationships = [:]
        if(available) {
            itemMap["title"] = "available"
        } else {
            itemMap["title"] = "not available"
        }
        if(statusMessage) itemMap['description'] = statusMessage
        if(workId) {
            relationships["http://jangle.org/vocab/Entities#Resource"]="${uri}/resources/"
        }
        if(borrowerId) {
            relationships["http://jangle.org/vocab/Entities#Actor"]="${uri}/actors/"
        }
        itemMap['relationships'] = relationships

        return itemMap
    }

    def donothing() {}
    def to_atom() {}

    def to_dlfexpanded() {
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        def writer = new StringWriter()
        def xml = new MarkupBuilder(writer)
        xml.record(xmlns:'http://diglib.org/ilsdi/1.1') {
            bibliographic(id:workUri)
            items {
                item(id:uri) {
                    simpleavailability {
                        identifier(uri)
                        if(available) {
                            availabilitystatus('available')
                        } else {
                            availabilitystatus('not available')
                        }
                        def locString = ''

                        if(location) {                            
                            locString = 'Location: '+location["name"]
                        }
                        if(classId) {
                            def classification = Classification.get(classId)
                            if(classification) {
                                def shelfmark = classification.classNumber
                                if(suffix) {shelfmark = shelfmark + ' ' + suffix}
                                if(locString.size() > 0) { locString = locString + ' - '}
                                locString = locString + 'Shelfmark: '+shelfmark
                            }
                        }
                        location(locString)
                        if(statusMessage) availabilitymsg(statusMessage)
                        if(dateAvailable) {dateavailable(dateFormatter.format(dateAvailable))}
                    }
                }
            }


        }
        return writer.toString()

    }

    def is_available() {
        switch(status_id) {
            case 5:
            available = true
            break
            default:
            available = false
        }
        if(onLoan) { available = false}

    }

    def setItemStatusMessage(mesg) {        
        if(!onLoan)
        {statusMessage = mesg}
        else
        {statusMessage = "On Loan"}
    }

    def getLocation() {
        return location
    }

    def setItemLocation(locMap) {
        location = locMap        
    }
    def getWork() {
        return WorkMetadata.get(workId)
    }
    
    def setVia(entity, ids) {
        via[entity] = ids
    }
    
    static def syncIndex() {
        def lastIndexed = search("*:*", sort:"modified", order:"desc", max:1)
        if (lastIndexed.total == 0) {
            return []
        }
        def newItems = findAllByModifiedGreaterThanEquals(lastIndexed.results[0].modified)
        if (newItems.size == 1 && newItems[0].id == lastIndexed.results[0].id) {
            return []
        }
        index(newItems)
        return newItems
    }    
    

}
