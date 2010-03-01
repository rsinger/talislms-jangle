import java.sql.Timestamp
class Holding {

    Long workId
    String locationId
    String fauxId
    String uri
    String baseUri
    Boolean available
    String statusMessage
    Map location

    Integer classId
    String holdings1
    String holdings2
    String holdings3
    String holdings4
    List holdingStatements = [holdings1, holdings2, holdings3, holdings4]
    String generalNote1
    String generalNote2
    String generalNote3
    String generalNote4
    List generalNotes = [generalNote1, generalNote2, generalNote3, generalNote4]
    String descriptiveNote1
    String descriptiveNote2
    String descriptiveNote3
    String descriptiveNote4
    List descriptiveNotes = [descriptiveNote1, descriptiveNote2, descriptiveNote3, descriptiveNote4]
    String wantsNote1
    String wantsNote2
    String wantsNote3
    String wantsNote4
    List wantsNotes = [wantsNote1, wantsNote2, wantsNote3, wantsNote4]
    String suffix
    Timestamp modified
    Map via = [:]
    
    static transients = ['uri', 'available', 'location','statusMessage', 
    'holdingStatements', 'generalNotes', 'descriptiveNotes', 'wantsNotes', 'via',
    'fauxId', 'modified', 'baseUri']
    static constraints = {
        classId(nullable:true)
        suffix(nullable:true)
        holdings1(nullable:true)
        holdings2(nullable:true)
        holdings3(nullable:true)
        holdings4(nullable:true)
        generalNote1(nullable:true)
        generalNote2(nullable:true)
        generalNote3(nullable:true)
        generalNote4(nullable:true)
        descriptiveNote1(nullable:true)
        descriptiveNote2(nullable:true)
        descriptiveNote3(nullable:true)
        descriptiveNote4(nullable:true)
        wantsNote1(nullable:true)
        wantsNote2(nullable:true)
        wantsNote3(nullable:true)
        wantsNote4(nullable:true)
    }
    def afterLoad = {
        
        def work = Work.get(workId)
        if(!work) {
            work = WorkMetadata.get(workId)
        }
        if(work) {
            modified = work.modified
        } else {
            modified = new Timestamp(0, 0, 0, 0, 0, 0, 0)
        }
        fauxId = 'h-'+id
    }
    static searchable = true

    static mapping = {
       table 'SITE_SERIAL_HOLDINGS'
       version false
        columns {
            id column: 'HOLDINGS_ID'
            workId column: 'WORK_ID'
            locationId column: 'LOCATION_ID'
            classId column: 'CLASS_ID'
            suffix column: 'SUFFIX'
            holdings1 column: 'HOLDINGS1'
            holdings2 column: 'HOLDINGS2'
            holdings3 column: 'HOLDINGS3'
            holdings4 column: 'HOLDINGS4'
            generalNote1 column: 'GENERAL_NOTE1'
            generalNote2 column: 'GENERAL_NOTE2'
            generalNote3 column: 'GENERAL_NOTE3'
            generalNote4 column: 'GENERAL_NOTE4'
            descriptiveNote1 column: 'DESCRIPTIVE_NOTE1'
            descriptiveNote2 column: 'DESCRIPTIVE_NOTE2'
            descriptiveNote3 column: 'DESCRIPTIVE_NOTE3'
            descriptiveNote4 column: 'DESCRIPTIVE_NOTE4'
            wantsNote1 column: 'WANTS_NOTE1'
            wantsNote2 column: 'WANTS_NOTE2'
            wantsNote3 column: 'WANTS_NOTE3'
            wantsNote4 column: 'WANTS_NOTE4'
        }

    }
    def setEntityUri(base) {
        baseUri = base
        uri = "${base}/items/${fauxId}"
    }
}
