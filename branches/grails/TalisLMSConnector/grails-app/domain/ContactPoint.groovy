class ContactPoint {
    Long addressId
    Boolean current
    static mapping = {
        table 'CONTACT_POINT'
        version false
        columns {
            id column: 'BORROWER_ID'
            addressId column: 'ADDRESS_ID'
            current column: 'CURRENT_CONTACT_POINT'
        }
    }

}
