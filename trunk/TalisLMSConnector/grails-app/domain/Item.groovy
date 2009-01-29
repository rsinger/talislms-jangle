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
    String workUri
    Boolean available
    String statusMessage
    static transients = ['uri','workUri','available', 'location','statusMessage']
    static mapping = {
       table 'ITEM'
       version false
       cache usage:'read-only'
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


    static constraints = {
        barcode(nullable:true)
        modified(nullable:true)
    }

    static def itemCheckFromWorks(worksList) {
        def works = [:]
        worksList.each {
            works[it.id.toInteger()] = it
        }
        def itemCheck = findAll("from Item as i where i.workId in (:workIds)",[workIds:works.keySet().toList()])
        itemCheck.each {
            if (it != null) {
                works[it.workId].setHasItems(true)
            }
        }

    }
    def setEntityUri(connectorBase) {
        if(!connectorBase) { connectorBase = ''}
        this.uri = "${connectorBase}/items/${id}"
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
        if(workId) {
            relationships["http://jangle.org/vocab/Entities#Resource"]="${uri}/resources/"
        }
        

        return itemMap
    }

    def donothing() {}

    def to_dlfexpanded() {
        def writer = new StringWriter()
        def xml = new MarkupBuilder(writer)
        xml.record(xmlns:'http://diglib.org/ilsdi/1.1') {
            bibliographic(id:workUri)
            simpleavailability {
                identifier(uri)
                if(available) {
                    availabilitystatus('available')
                } else {
                    availabilitystatus('not available')
                }
                if(statusMessage) availabilitymsg(statusMessage)
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

    }

    def setStatusMessage(mesg) {
        statusMessage = mesg
    }

    def getLocation() {

    }
    

}
