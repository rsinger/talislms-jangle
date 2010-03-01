import java.text.SimpleDateFormat
/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author rosssinger
 */
class FeedResponse {
    String type = 'feed'
    Integer totalResults = 0
    Integer offset = 0
    Date time = new java.util.Date()
    String request
    Map alternateFormats
    List formats
    List data
    List stylesheets
    List categories

    def setTotalResults(num) {
        totalResults = num
    }

    def setOffset(num) {
        offset = num
    }

    def setTime(date) {
        time = date.toString()
    }

    def setRequest(uri) {
        request = uri
    }
    def addAlternateFormat(format_uri, location) {
        if(!alternateFormats) { alternateFormats = [:]}
        alternateFormats[format_uri] = location
    }

    def addFormat(format_uri) {
        if(!formats) { formats = []}
        if(!formats.contains(format_uri)) { formats << format_uri }
    }

    def addStylesheet(stylesheet) {
        if(!stylesheets) { stylesheets = [] }
        stylesheets << stylesheet
    }

    def addCategory(category) {
        if(!categories) { categories = [] }
        if(!categories.contains(category)) { categories << category }
    }

    def addData(dataMap) {
        if(!data) { data = []}
        data << dataMap
        if(dataMap['format']) { addFormat(dataMap['format']) }
    }

    def toMap() {
        def dateFormatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
        def responseMap = ["type":type,"request":request,"time":dateFormatter.format(time),
        "totalResults":totalResults,"offset":offset,"alternate_formats":alternateFormats,
        "formats":formats,"stylesheets":stylesheets,"categories":categories,
        "data":data]
        return responseMap
    }
}

