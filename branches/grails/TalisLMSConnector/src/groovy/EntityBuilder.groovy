/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author rosssinger
 */
import org.apache.commons.dbcp.BasicDataSource
import groovy.sql.Sql
class EntityBuilder {
    
    BasicDataSource dataSource
    def config
    //def typeStatus = ctx.typeStatusService
    //def request = ctx.requestService
    def statusMap = [:]
    String connectorBase


    def setEntityAttributes(entities) {
        for(entity in entities) {
            entity.setEntityUri(connectorBase)
            switch(entity.getClass()) {
                case Borrower:                    
                    break
                case WorkCollection:                    
                    break
                case Item:
                    entity.setStatusMessage(getStatusMessage(6,entity.status_id))
                    break
                case WorkMetadata:
                    setResourceAttributes(entities)
                    break
            }
        }
    }

    
    
    def setConnectorBase(header=null) {
        connectorBase = header ? header : ''

    }
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

