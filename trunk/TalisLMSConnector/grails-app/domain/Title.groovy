class Title {
    Integer collectionId
    Long workId
    String title
    static mapping = {
       table 'TITLE'
       version false
       cache usage: 'read-only'
        columns {
            id column: 'TITLE_ID'
            workId column: 'WORK_ID'
            collectionId column: 'COLLECTION_ID'
            title column: 'TITLE_DISPLAY'
        }

    }

    static def getTitlesForWorks(worksList) {
        def works = [:]
        worksList.each {
            works[it.id] = it
        }
        def titleList = findAll("from Title as t where t.workId in (:workIds)",[workIds:works.keySet().toList()])

        titleList.each {
            
            if (it != null) {
                works[it.workId].setTitle(it.title)
                works[it.workId].addCollection(it.collectionId)
            }
        }
    }

    

}
