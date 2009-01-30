import groovy.xml.MarkupBuilder
import java.util.Formatter.DateTime
import java.text.SimpleDateFormat
class WorkCollection {
    String name
    String collectionCode    
    String uri
    Boolean hasWorks = false
    static transients = ['hasWorks', 'uri']
    static mapping = {
       table 'COLLECTION'
       version false       
        columns {
            id column: 'COLLECTION_ID'
            name column: 'NAME'
            collectionCode column: 'CODE'
        }

    }

    def setEntityUri(base) {
        uri = "${base}/collections/${id}"
    }
    
    def toMap() {        
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        def collMap = ["id":uri,"title":name, "updated":dateFormatter.format(new Date())]        
        checkHasWorks()
        if(hasWorks) {
            collMap["relationships"] = ["http://jangle.org/vocab/Entities#Resource":
            "${uri}/resources/"]
        }

        return collMap
    }

    def to_dc() {

        def writer = new StringWriter()
        def xml = new MarkupBuilder(writer)

        xml.'rdf:Description'(['xmlns:rdf':'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            'xmlns:dc':'http://purl.org/dc/elements/1.1/','rdf:about':uri]) {
            'dc:title'(name)
            'dc:identifier'(uri)
            'dc:type'("rdf:resource":"http://purl.org/dc/dcmitype/Collection","Collection")
            'rdf:Type'("rdf:resource":"http://purl.org/dc/dcmitype/Collection")
            'dc:source'('http://jangle.org/vocab/Entity#Collection')

        }
        return writer.toString()
    }

    def checkHasWorks() {
        def workCheck = Title.findByCollectionIdAndWorkIdIsNotNull(id)
        if(workCheck) {
            hasWorks = true
        }
    }

    static def findAllByWorkId(workId) {
        def collections = []
//        def c = Title.createCriteria()
//        def collections = c.list {
//            distinct('collectionId')
//            eq('workId',workId)
//        }
        Title.executeQuery("SELECT DISTINCT t.collectionId FROM Title t WHERE t.workId = ?", [workId]).each {
            collections << WorkCollection.get(it)
        }
        collections
    }

    def getWorks(offset=0) {
        def works = WorkMetadata.findByCollectionId(id,offset)
        return works

    }

}
