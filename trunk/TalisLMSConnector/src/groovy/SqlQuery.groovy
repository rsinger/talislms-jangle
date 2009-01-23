/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author rosssinger
 */
import org.codehaus.groovy.grails.commons.ApplicationHolder as AH
import org.springframework.web.context.WebApplicationContext as WAC
import groovy.sql.Sql
class SqlQuery {
    def ctx = AH.application.parentContext.servletContext.attributes.(WAC.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE)
    def dataSource = ctx.dataSource
    def getLocation(id, siteId = null) {
        def sql = new Sql(dataSource)
        def result
        if(siteId) {
            result = sql.rows("SELECT LOCATION_ID, NAME, NOTE, TYPE, WITHIN_SITE_ID FROM LOCATION WHERE LOCATION_ID = ${id} AND WITHIN_SITE_ID = ${siteId}")
        } else {
            result = sql.rows("SELECT LOCATION_ID, NAME, NOTE, TYPE, WITHIN_SITE_ID FROM LOCATION WHERE LOCATION_ID = ${id} AND (WITHIN_SITE_ID IS NULL OR WITHIN_SITE_ID = '')")
        }
        [result:result]
    }

    def getItemLocations(items) {
        def sites = []
        items.each {
            if(!sites.contains(it.site)) { sites << it.site }
        }
        def sql = new Sql(dataSource)
        def result
    }
	
}

