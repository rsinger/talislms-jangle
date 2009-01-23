import groovy.xml.MarkupBuilder
import java.util.Formatter.DateTime
import java.text.SimpleDateFormat
class WorkCollection {
    String name
    String collectionCode
    def requestService
    String uri
    Boolean hasWorks = false
    static transients = ['requestService', 'hasWorks', 'uri']
    static mapping = {
       table 'COLLECTION'
       version false
        columns {
            id column: 'COLLECTION_ID'
            name column: 'NAME'
            collectionCode column: 'CODE'
        }

    }

    def toMap(format="dc") {
        uri = "${requestService.connectorBase}/collections/${id}"
        def collMap = ["id":uri,"title":name]
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        checkHasWorks()
        if(hasWorks) {
            collMap["relationships"] = ["http://jangle.org/vocab/Entities#Resource":
            "${uri}/resources/", "updated":dateFormatter.format(new Date())]
        }
        switch(format) {
            default:
                toDc(collMap)
        }
        return collMap
    }

    def toDc(collMap) {
        collMap["content_type"] = "application/xml"
        collMap["format"] = "http://jangle.org/vocab/formats#http://purl.org/dc/elements/1.1/"
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




        collMap["content"] = writer.toString()
    }

    def checkHasWorks() {
        def workCheck = Title.findByCollectionIdAndWorkIdIsNotNull(id)
        if(workCheck) {
            hasWorks = true
        }
    }

    static def findAllByWorkId(workId) {
        def collections = []
        Title.executeQuery("SELECT DISTINCT t.collectionId FROM Title t WHERE t.workId = ?", [workId]).each {
            collections << WorkCollection.get(it)
        }
        collections
    }

}
