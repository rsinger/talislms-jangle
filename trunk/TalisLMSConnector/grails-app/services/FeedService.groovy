import org.codehaus.groovy.grails.commons.ConfigurationHolder
class FeedService {
    def config = ConfigurationHolder.config.jangle.connector
    boolean transactional = true
    def connectorBase
    def statusMap = [:]
    def buildFeed(feed,entries,params) {
        def entity
        switch(entries[0].getClass()) {
            case Borrower:
                entity = 'actors'
                break
            case WorkCollection:
                entity = 'collections'
                break
            case Item:
                entity = 'items'
                break
            case WorkMetadata:
                entity = 'resources'
                break
        }
        if(!params.format) { params.format = config.entities[entity].record_types[0]}
        if(config.entities[entity].record_types.size() > 1) {
            addFeedAlternateFormats(feed,params.format,config.entities[entity].record_types)
        }
        for(entry in entries) {
            if(entity == 'items') { entry.setStatusMessage(getStatusMessage(6,entry.status_id))}
            entry.setEntityUri(connectorBase)
            def entryMap = entry.toMap()
            def method_name
            if(config.entities[entity].method_aliases && config.entities[entity].method_aliases[params.format]) {
                method_name = 'to_'+config.entities[entity].method_aliases[params.format]
            } else {
                method_name = 'to_'+params.format
            }
            entryMap["content"] = entry.invokeMethod(method_name,null)
            entryMap["content_type"] = config.record_types[params.format]["content-type"]
            entryMap["format"] = config.record_types[params.format]["uri"]
            feed.addData(entryMap)
            if(config.entities[entity].record_types.size() > 1) {
                addEntryAlternateFormats(entryMap,params.format,config.entities[entity].record_types)
            }
        }

    }

    def setConnectorBase(header=null) {
        connectorBase = header ? header : ''

    }

    def setResourceAttributes(works) {
        Item.itemCheckFromWorks(works)
        Title.getTitlesForWorks(works)
        entityBuilder.setEntityAttributes(works)
    }

    def addFeedAlternateFormats(feed,fmt,altFormats) {
        def fmtUri
        def feedUri = (connectorBase+(feed.request =~ /^[^\/]*${config.global_options.servlet_path}/).replaceFirst('')).toURI()

        def deformattedFeedUri
        if(feedUri.getQuery() && feedUri.getQuery() =~ /format=/) {
            deformattedFeedUri = (feedUri.toString() =~ /format=[^&]*\&?/).replaceFirst("")
            if(!deformattedUri.endsWith("?")) {
                deformattedUri =  deformattedUri+'&'
            }
        } else if(!feedUri.getQuery()) {
            deformattedFeedUri = feedUri.toString()+"?"
        } else {
            deformattedFeedUri = feedUri.toString()+"&"
        }
        altFormats.each {
            if(it != fmt) {
                fmtUri = config.record_types[it].uri
                feed.addAlternateFormat(fmtUri,deformattedFeedUri+"format=${it}")
            }
        }
    }

    def addEntryAlternateFormats(entry,fmt,altFormats) {
        def fmtUri
        entry["alternate_formats"] = [:]
        altFormats.each {
            if(it != fmt) {
                fmtUri = config.record_types[it].uri
                entry["alternate_formats"][fmtUri] = entry["id"]+"?format=${it}"
            }
        }
    }

    def getStatusMessage(subtype,typeId) {
        if(!statusMap[subtype]) { loadMapValues(subtype) }
        return statusMap[subtype][typeId]
    }

    def loadMapValues(subtype) {
        statusMap[subtype] = [:]
        TypeStatus.findAllBySubType(subtype).each {
            statusMap[subtype][it.typeId] = it.name
        }
    }
}
