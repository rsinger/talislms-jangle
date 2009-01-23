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
    def requestService
    String uri
    static transients = ['requestService','uri']
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

    def toMap(format='vcard') {
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        uri = "${requestService.connectorBase}/actors/${id}"
        def borrowerMap = ["id":uri,
        "title":"${surname}, ${first_names}","updated":dateFormatter.format(modified),
        "created":dateFormatter.format(created)]
        switch(format) {
            default:
                toVcard(borrowerMap)
        }
        return borrowerMap
    }

    def toVcard(borrowerMap) {
        borrowerMap["content_type"] = "text/x-vcard"
        borrowerMap["format"] = "http://jangle.org/vocab/formats#text/x-vcard"
        def dateFormatter = new org.apache.log4j.helpers.ISO8601DateFormat()
        def vcard="BEGIN:VCARD\nVERSION:3.0\nFN:${first_names} ${surname}\n"
        vcard = "${vcard}N:${surname};${first_names};;;\n"
        vcard = "${vcard}BDAY:${dateFormatter.format(birth_date)}\n"
        vcard = "${vcard}URL:${uri}\n"
        vcard = "${vcard}REV:${dateFormatter.format(modified)}\n"
        vcard = "${vcard}X-BARCODE:${barcode}\nEND:VCARD\n"
        borrowerMap["content"] = vcard

    }
}
