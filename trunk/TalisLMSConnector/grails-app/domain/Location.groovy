class Location implements Serializable {
    String locationId
    String name
    String withinSiteId
    static mapping = {
        table 'LOCATION'
        version false
        id composite: ['locationId','withinSiteId']
        columns {
            locationId column: 'LOCATION_ID'
            withinSiteId column: 'WITHIN_SITE_ID'
            name column: 'NAME'
        }
    }
}
