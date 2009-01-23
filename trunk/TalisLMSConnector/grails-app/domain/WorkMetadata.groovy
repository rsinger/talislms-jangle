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
    Boolean opac_suppress
    String control_number
    Timestamp modified
    Boolean hasItems
    List collections = []
    String title
    String uri
    def requestService
    static transients = ['record', 'hasItems', 'collections', 'title', 'uri', 'requestService']
    static mapping = {
        table 'WORKS_META'
        version false
        columns {
            id column: 'WORK_ID'
            raw_data column: 'RAW_DATA'
            control_number column: 'TALIS_CONTROL_NUMBER'
            opac_suppress column: 'SUPPRESS_FROM_OPAC'
            modified column: 'MODIFIED_DATE'
        }
    }

    def raw_to_record() {
        def bis = new ByteArrayInputStream(raw_data)
        def reader = new RecordReader(bis)
        record = reader.getNext()
    }

    def toMap(format="marcxml") {
        if(raw_data && !record) {raw_to_record()}
        if(!title) {getTitleFrom245()}
        if(hasItems == null) {Item.itemCheckFromWorks(this)}
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        uri = "${requestService.connectorBase}/resources/${id}"
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
        workMap["relationships"] = relationships
        switch(format) {
            case "marc":
                this.toMarc(workMap)
                break
            case "mods":
                this.toMods(workMap)
                break
            case "dc":
                this.toDc(workMap)
                break
            case "oai_dc":
                this.toOaiDc(workMap)
                break
            case "atom":
                doNothing()
                break
            default:
                this.toMarcXml(workMap)
        }
        setAlternateFormats(workMap,format)
        return workMap
    }

    def doNothing() {}

    def toMarc(workMap) {
        workMap["content_type"] = "application/marc"
        workMap["content"] = record.ToISO2709().encodeBase64().toString()
        workMap["format"] = "http://jangle.org/vocab/formats#application/marc"
    }

    def toMods(workMap) {
        toMarcXml(workMap)
        workMap["format"] = "http://jangle.org/vocab/formats#http://www.loc.gov/mods/v3"
    }

    def toDc(workMap) {
        toMarcXml(workMap)
        println "Hello"
        workMap["format"] = "http://jangle.org/vocab/formats#http://purl.org/dc/elements/1.1/"
    }

    def toOaiDc(workMap) {
        toMarcXml(workMap)
        workMap["format"] = "http://jangle.org/vocab/formats#http://www.openarchives.org/OAI/2.0/oai_dc/"
    }
    def toMarcXml(workMap) {
        workMap["content_type"] = "application/xml"
     
        def strWriter = new StringWriter()
        def serializer = new org.apache.xml.serialize.XMLSerializer()
        serializer.setOutputCharStream(strWriter)
        serializer.serialize(record.toMarcXml())
        def marcList = strWriter.toString().split(/\n/)
        workMap["content"] = marcList[1..(marcList.size()-1)][0].replaceAll(
            /\<record\>/,'<record xmlns="http://www.loc.gov/MARC21/slim">')
        workMap["format"] = "http://jangle.org/vocab/formats#http://www.loc.gov/MARC21/slim"

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

    def getItems(offset=0,format="dlfexpanded") {
        def items = Item.findAllByWorkId(this.id,[sort:"modified",order:"desc",offset:offset])
        def itemList = []
        items.each {
            itemList << it.toMap(format)
        }
        return itemList
    }



    def validFormats() {
        return ["marcxml":"http://jangle.org/vocab/formats#http://www.loc.gov/MARC21/slim",
        "marc":"http://jangle.org/vocab#application/marc",
        "dc":"http://purl.org/dc/elements/1.1/",
        "oai_dc":"http://jangle.org/vocab/formats#http://www.openarchives.org/OAI/2.0/oai_dc/",
        "mods":"http://jangle.org/vocab/formats#http://www.loc.gov/mods/v3"]

    }

}