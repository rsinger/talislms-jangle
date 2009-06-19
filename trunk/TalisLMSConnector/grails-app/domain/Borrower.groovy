import java.sql.Timestamp
import java.text.SimpleDateFormat
import groovy.xml.MarkupBuilder
class Borrower {
    String barcode
    String surname
    String firstNames
    String pin
    Date birthDate
    Date registrationDate
    Timestamp created
    Timestamp modified
    Timestamp expiration    
    String uri
    static transients = ['uri']
    static mapping = {
        table 'BORROWER'
        version false
        columns {
            id column: 'BORROWER_ID'
            barcode column: 'BARCODE'
            surname column: 'SURNAME'
            firstNames column: 'FIRST_NAMES'
            birthDate column: 'DATE_OF_BIRTH'
            registrationDate column: 'REGISTRATION_DATE'
            created column: 'CREATE_DATE'
            modified column: 'EDIT_DATE'
            expiration column: 'EXPIRY_DATE'
            pin column: 'PIN'
        }
    }

    static constraints = {
        pin(nullable:true)
    }

    def setEntityUri(base) {
        uri = "${base}/actors/${id}"
    }

    def toMap() {
  
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")       
        if(modified == null) {
            modified = new java.sql.Timestamp(new Date().getTime())
        }         
        def borrowerMap = ["id":uri,
        "title":"${surname}, ${firstNames}","updated":dateFormatter.format(modified),
        "created":dateFormatter.format(created)]

        return borrowerMap
    }

    def to_vcard() {
        def dateFormatter = new org.apache.log4j.helpers.ISO8601DateFormat()
        def vcard="BEGIN:VCARD\nVERSION:3.0\nFN:${firstNames} ${surname}\n"
        vcard = "${vcard}N:${surname};${firstNames};;;\n"
        vcard = "${vcard}BDAY:${dateFormatter.format(birthDate)}\n"
        vcard = "${vcard}URL:${uri}\n"
        vcard = "${vcard}REV:${dateFormatter.format(modified)}\n"
        vcard = "${vcard}X-BARCODE:${barcode}\nEND:VCARD\n"
        return(vcard)
    }
    def to_foaf() {
        def writer = new StringWriter()
        def xml = new MarkupBuilder(writer)
        xml.'rdf:RDF'(['xmlns:rdf':'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            'xmlns:foaf':'http://xmlns.com/foaf/0.1/']) {
                'foaf:Person'(['rdf:about':uri]) {
                    'foaf:firstName'(firstNames)
                    'foaf:surname'(surname)
                    'foaf:name'("${firstNames} ${surname}")
                    'foaf:holdsAccount'(['rdf:resource':uri]) {
                        'foaf:OnlineAccount'(['rdf:about':uri]) {
                            'foaf:accountName'(barcode)
                        }
                    }
                }
        }
        return writer.toString()                
    }
}
