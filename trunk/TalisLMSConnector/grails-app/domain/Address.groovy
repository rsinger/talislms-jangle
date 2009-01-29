class Address {
    String line1
    String line2
    String line3
    String line4
    String line5
    String postcode
    String phone
    String ext
    String fax

    static mapping = {
        table 'ADDRESS'
        version false
        columns {
            id column: 'ADDRESS_ID'
            line1 column: 'LINE_1'
            line2 column: 'LINE_2'
            line3 column: 'LINE_3'
            line4 column: 'LINE_4'
            line5 column: 'LINE_5'
            postcode column: 'POST_CODE'
            phone column: 'TELEPHONE_NO'
            ext column: 'EXTENSION'
            fax column: 'FAX_NO'
        }
    }

}
