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
    String time = new java.util.Date().toString()

    def getBasePath() {
        //if(!basePath) {
            def m = request =~ /(\/[^\/]*)\/services\/?/
            basePath = m[0][1]
        //}
        return basePath
    }
    def entities() {
       return ["Actor":["title":"Alto Borrowers",
        "searchable":false,"path":"/actors/"],
        "Collection":["title":"Types of Works and Locations","searchable":false,
        "path":"/collections/"],
        "Item":["title":"Copies and Holdings", "searchable":false,
        "path":"/items/"],
        "Resource":["title":"Works","searchable":false,
        "path":"/resources/"]]
        
    }
    Map categories

    def toMap() {
        def responseMap = ["type":type,"version":version,"title":title,
        "time":time,"request":request,"entities":entities(),"categories":categories,
        "base":basePath]
        return responseMap
    }
}

