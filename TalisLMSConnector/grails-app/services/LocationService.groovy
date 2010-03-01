import groovy.sql.Sql


class LocationService {

    boolean transactional = true
    def dataSource
    

    def getLocation(id, siteId = "NULL") {
        def sql = new Sql(dataSource)

        def result = sql.rows(
            "SELECT LOCATION_ID, NAME, NOTE, TYPE, WITHIN_SITE_ID FROM LOCATION WHERE LOCATION_ID = ${id} AND WITHIN_SITE_ID = ${siteId}")
        [result:result]
    }
}
