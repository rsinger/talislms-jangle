import org.codehaus.groovy.grails.commons.ConfigurationHolder
class FeedService {
    def config = ConfigurationHolder.config.jangle.connector
    boolean transactional = true
    def connectorBase
    def statusMap = [:]
    def locations = [:]
    def buildFeed(feed,entries,params) {
        def entity
        switch(entries[0].getClass()) {
            case Borrower:
                entity = 'actors'
                break
            case WorkCollection:
                //setCollectionAttributes(entries)
                entity = 'collections'
                break
            case Item:
                setItemAttributes(entries)
                entity = 'items'
                break
            case WorkMetadata:
                setResourceAttributes(entries)
                entity = 'resources'
                break
        }
        if(!params.format) { params.format = config.entities[entity].record_types[0]}
        if(config.entities[entity].record_types.size() > 1) {
            addFeedAlternateFormats(feed,params.format,config.entities[entity].record_types)
        }
        if(config.record_types[params.format].stylesheets && config.record_types[params.format].stylesheets.feed && config.record_types[params.format].stylesheets.feed.entities && config.record_types[params.format].stylesheets.feed.entities.contains(entity)) {
           feed.addStylesheet(config.record_types[params.format].stylesheets.feed.uri)
        }
        for(entry in entries) {            
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
        // Ugly hack to weed out possible works that have no MARC record.
        def cleanWorks = []
        works.each {
            if(it.raw_data) { cleanWorks << it}
        }
        works = cleanWorks
        Item.itemCheckFromWorks(works)
        Title.getTitlesForWorks(works)        
    }

    def setItemAttributes(items) {
        if(!locations) {locations = [:]}
        def locs = Location.executeQuery("SELECT locationId, name, withinSiteId FROM Location")
        locs.each {
            if(!locations[it[0].trim()]) locations[it[0].trim()] = [:]

            locations[it[0].trim()] = ["locationId":it[0],"name":it[1],"withinSiteId":it[2]]
        }
        locations.each { siteId, site ->
            if(site["withinSiteId"] && site["withinSiteId"].trim() != '') {
                println site["withinSiteId"].trim()
                site["name"] = locations[site["withinSiteId"].trim()]["name"]+"/"+site["name"]
            }
        }
        def allIds = []
        def loanedItemIds = []
        def orderedItemIds = []
        def serialItemIds = []
        Loan.findCurrentLoansFromItemList(items)
        items.each {
            if(it.onLoan) {
                it.setStatusMessage("On Loan")
            } else {
                it.setStatusMessage(getStatusMessage(6,it.status_id))
            }
            allIds << it.id

            if(it.site && locations[it.site.trim()]) {                
                it.setItemLocation(locations[it.site.trim()])                
            }
            if(it.status_id != 5) {
                if(it.status_id == 1 || it.status_id == 2) {
                    orderedItemIds << it.id
                } else {
                    loanedItemIds << it.id
                }
            }
        }



    }

    def setCollectionAttributes(collections) {
        Title.checkWorksFromCollections(collections)
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
