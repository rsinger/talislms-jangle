class Location {
    String LOCATION_ID
    String name
    String WITHIN_SITE_ID
    static mapping = {
        table 'LOCATION'
        version false
        columns {

            id composite: ['LOCATION_ID','WITHIN_SITE_ID']
            name column: 'NAME'
        }
    }
}
