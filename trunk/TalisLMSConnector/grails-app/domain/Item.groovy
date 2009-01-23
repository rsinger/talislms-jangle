import java.sql.Timestamp
import groovy.xml.MarkupBuilder
import java.text.SimpleDateFormat
class Item {
    String barcode
    Integer status_id
    Integer workId
    String site
    Timestamp modified
    Timestamp created
    String uri
    String connectorBase
    Boolean available
    String location
    def requestService
    static transients = ['uri','connectorBase','available', 'location','requestService']
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
        }

    }

    static def itemCheckFromWorks(worksList) {
        def works = [:]
        worksList.each {
            works[it.id.intValue()] = it
        }
        def itemCheck = findAll("from Item as i where i.workId in (:workIds)",[workIds:works.keySet().toList()])
        itemCheck.each {
            if (it != null) {
                works[it.workId.intValue()].setHasItems(true)
            }
        }

    }

    def toMap(format="dlfexpanded") {
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        
        is_available()
        uri = "${requestService.connectorBase}/items/${id}"
        def itemMap = ["id":uri,
            "updated":dateFormatter.format(modified),
            "created":dateFormatter.format(created)]
        def relationships = [:]
        if(available) {
            itemMap["title"] = "available"
        } else {
            itemMap["title"] = "not available"
        }
        if(workId) {
            relationships["http://jangle.org/vocab/Entities#Resource"]="${uri}/resources/"
        }
        
        switch(format) {
            case 'atom':
                donothing()
                break
            default:
                toDlfExpanded(itemMap)                
        }

        return itemMap
    }

    def donothing() {}

    def toDlfExpanded(itemMap) {
        def writer = new StringWriter()
        def xml = new MarkupBuilder(writer)
        itemMap['content_type'] = 'application/xml'
        itemMap['format'] = "http://jangle.org/vocab/formats#http://diglib.org/ilsdi/1.0"
        xml.record(xmlns:'http://diglib.org/ilsdi/1.1') {
            bibliographic(id:"${requestService.connectorBase}/resources/${workId}")
            simpleavailability {
                identifier(uri)
                if(available) {
                    availabilitystatus('available')
                } else {
                    availabilitystatus('not available')
                }                
            }


        }
        itemMap["content"] = writer.toString()

    }

    def is_available() {
        available = true
        Loan.findAllByItemId(id).each {
            if(it.currentLoan == true) {
                available = false
            }
        }

    }

    def getLocation() {

    }
    

}
