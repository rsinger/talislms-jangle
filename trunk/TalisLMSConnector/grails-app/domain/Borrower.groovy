import java.sql.Timestamp
import java.text.SimpleDateFormat
class Borrower {
    String barcode
    String surname
    String first_names
    Date birth_date
    Date registration_date
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
            first_names column: 'FIRST_NAMES'
            birth_date column: 'DATE_OF_BIRTH'
            registration_date column: 'REGISTRATION_DATE'
            created column: 'CREATE_DATE'
            modified column: 'EDIT_DATE'
            expiration column: 'EXPIRY_DATE'
        }
    }

    def setEntityUri(base) {
        uri = "${base}/actors/${id}"
    }

    def toMap() {
  
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")        
        def borrowerMap = ["id":uri,
        "title":"${surname}, ${first_names}","updated":dateFormatter.format(modified),
        "created":dateFormatter.format(created)]

        return borrowerMap
    }

    def to_vcard() {
        def dateFormatter = new org.apache.log4j.helpers.ISO8601DateFormat()
        def vcard="BEGIN:VCARD\nVERSION:3.0\nFN:${first_names} ${surname}\n"
        vcard = "${vcard}N:${surname};${first_names};;;\n"
        vcard = "${vcard}BDAY:${dateFormatter.format(birth_date)}\n"
        vcard = "${vcard}URL:${uri}\n"
        vcard = "${vcard}REV:${dateFormatter.format(modified)}\n"
        vcard = "${vcard}X-BARCODE:${barcode}\nEND:VCARD\n"
        return(vcard)

    }
}
