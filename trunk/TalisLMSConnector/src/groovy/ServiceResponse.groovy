import java.text.SimpleDateFormat
/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author rosssinger
 */
class ServiceResponse {
    String type = 'services'
    String version = '1.0'
    String title = 'Talis OPAC'
    String request
    private String basePath
    Date time = new java.util.Date()
    Map entities = [:]
    List categories

    def getBasePath() {
        //if(!basePath) {
            def m = request =~ /(\/[^\/]*)\/services\/?/
            basePath = m[0][1]
        //}
        return basePath
    }

    def buildFromConfig(conf) {
        title = conf.global_options.service_name
        conf.entities.each {ent,vals ->
            def entity_key
            
            switch(ent) {
                case 'actors':
                    entity_key = 'Actor'
                    break
                case 'collections':
                    entity_key = 'Collection'
                    break
                case 'items':
                    entity_key = 'Item'
                    break
                case 'resources':
                    entity_key = 'Resource'
                    break
            }
            def eMap = ['path':"/$ent/"]
            if(vals.title) {
                eMap['title'] = vals.title
            } else {
                eMap['title'] = ent
            }

            if(!vals.search) {
                eMap["search"] = false
            } else {
                eMap["search"] = "/$ent/explain"
            }
            if(vals.categories) {eMap["categories"] = vals.categories}
            entities[entity_key] = eMap
        }
        if(conf.categories) {
            categories = []
            conf.categories.each {term, vals ->
                def catMap = ['term':term]
                if(vals.scheme) { catMap['scheme'] = vals.scheme}
                if(vals.label) { catMap['label'] = vals.label}
                categories << catMap

            }
        }
    }
    

    def toMap() {
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        def responseMap = ["type":type,"version":version,"title":title,
        "time":dateFormatter.format(time),"request":request,"entities":entities,
        "categories":categories]
        return responseMap
    }
}

