import java.sql.Timestamp
import java.io.ByteArrayInputStream
//import org.marc4j.MarcReader
//import org.marc4j.MarcPermissiveStreamReader
//import org.marc4j.marc.Record
import com.talis.data.iso2709.RecordParser
import com.talis.data.iso2709.Record
import com.talis.data.iso2709.RecordReader
import java.text.SimpleDateFormat
class WorkMetadata {
    Byte[] raw_data
    Record record
    String opacSuppress
    String indexSuppress
    String controlNumber
    Timestamp modified
    Boolean hasItems
    List collections = []
    String title
    String uri

    static transients = ['record', 'hasItems', 'collections', 'title', 'uri']
    static mapping = {
        table 'WORKS_META'
        version false        
        columns {
            id column: 'WORK_ID'
            raw_data column: 'RAW_DATA'
            controlNumber column: 'TALIS_CONTROL_NUMBER'
            opacSuppress column: 'SUPPRESS_FROM_OPAC'
            indexSuppress column: 'SUPPRESS_FROM_INDEX'
            modified column: 'MODIFIED_DATE'
        }
    }
    static constraints = {
        raw_data(nullable:true)
    }

    def setEntityUri(base) {
        uri = "${base}/resources/${id}"
    }
    def raw_to_record() {
        if(raw_data) {
            def bis = new ByteArrayInputStream(raw_data)
            def reader = new RecordReader(bis)
            record = reader.getNext()
        }
    }

    def setHasItems(flag) {
        hasItems = flag
    }

    def toMap() {
        if(raw_data && !record) {raw_to_record()}
        if(!title) {getTitleFrom245()}
        if(title == '') {title = 'n/a'}
        //if(hasItems == null) {Item.itemCheckFromWorks(this)}
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        
        def workMap = ["id":uri,"title":title,
        "updated":dateFormatter.format(modified)]
        def relationships = [:]
        if(collections.size() > 0) {
            relationships["http://jangle.org/vocab/Entities#Collection"] =
                "${uri}/collections/"
        }
        if(hasItems) {
            relationships["http://jangle.org/vocab/Entities#Item"] =
                "${uri}/items/"
        }
        if(!opacSuppress) { workMap["categories"] = ['opac']}
        workMap["relationships"] = relationships
        return workMap
    }

    def doNothing() {}

    def to_marc() {
        if(record) {
            return record.ToISO2709().encodeBase64().toString()
        } else {
            return ''
        }
    }

    def to_marcxml() {
        if(!record) { return ''}
        def strWriter = new StringWriter()
        def serializer = new org.apache.xml.serialize.XMLSerializer()
        serializer.setOutputCharStream(strWriter)
        serializer.serialize(record.toMarcXml())
        def marcList = strWriter.toString().split(/\n/)
        return marcList[1..(marcList.size()-1)].join("\n").replaceAll(
            /\<record\>/,'<record xmlns="http://www.loc.gov/MARC21/slim">')

    }

    def setTitle(str) {
        title = str
    }

    def addCollection(num) {
        if(!collections.find{it == num}) {collections << num}
    }

    def getTitleFrom245() {        
        if(!record) {raw_to_record()}
        def titleField = record.getDataFields('245')
        if(!titleField) {
            title = ''
            return
        }
        title = titleField[0].getSubfields('a')[0].getContent('utf-8')

    }
    def getTitleFromTitle() {
        def titles = Title.findAllByWorkId(id)
        titles.each {
            title = it.title
            this.addCollection(it.collectionId)
        }
    }

    def setAlternateFormats(workMap, format) {
        def formats = validFormats()
        workMap["alternate_formats"] = [:]
        formats.each { key,val ->
            if(key != format) {
                workMap["alternate_formats"][val] = "${uri}?format=${key}"
            }
        }
    }

    def getItems(offset=0) {
        def items = Item.findAllByWorkId(this.id,[sort:"modified",order:"desc",offset:offset])
        return items
    }

    def getCollections(offset=0) {
        def colls = WorkCollection.findAllByWorkId(this.id)
        return colls
    }


    def validFormats() {
        return ["marcxml":"http://jangle.org/vocab/formats#http://www.loc.gov/MARC21/slim",
        "marc":"http://jangle.org/vocab/formats#application/marc",
        "dc":"http://jangle.org/vocab/formats#http://purl.org/dc/elements/1.1/",
        "oai_dc":"http://jangle.org/vocab/formats#http://www.openarchives.org/OAI/2.0/oai_dc/",
        "mods":"http://jangle.org/vocab/formats#http://www.loc.gov/mods/v3"]

    }

    static def findByCollectionId(collectionId, offset=0) {
        def workIds = WorkMetadata.executeQuery(
            "SELECT w.id FROM WorkMetadata w, Title t WHERE w.id = t.workId AND t.collectionId = 1 ORDER BY w.modified DESC", [max:100,offset:offset])
        return WorkMetadata.getAll(workIds)
    }

}