import groovy.sql.Sql
class TypeStatusService {
    def dataSource
    def statusMap = [:]
    def getStatusMessage(subtype,typeId) {
        if(!statusMap[subtype]) { loadMapValues(subtype) }
        return statusMap[subtype][typeId]
    }

    def loadMapValues(subtype) {
        statusMap[subtype] = [:]
        def sql = new Sql(dataSource)
        sql.eachRow("SELECT * FROM TYPE_STATUS WHERE SUB_TYPE = ${subtype}") { status ->
            statusMap[subtype][status.TYPE_STATUS] = status.NAME
        }
    }
}
