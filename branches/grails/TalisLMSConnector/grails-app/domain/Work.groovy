import java.sql.Timestamp
class Work {
    String title
    String author
    Timestamp modified
    Timestamp created
    public Boolean hasItems

//    static hasMany = [ items : Item ]
    static mapping = {
        table 'WORKS'
        version false
        columns {
            id column: 'WORK_ID'
            title column:  'TITLE_DISPLAY'
            author column: 'AUTHOR_DISPLAY'
            created column: 'CREATE_DATE'
            modified column: 'EDIT_DATE'
//            items column: 'WORK_ID'
        }
    }

    def item_count() {
        return Item.countByWorkId(id)
    }

    def toMap(base_url = null) {
        def work_map = ["id":"${base_url}/resources/${id}","title":title,"author":author,"updated":modified,
        "created":created]
        if (hasItems) {
            work_map["relationships"] = ["http://jangle.org/vocab/Entities#Item":
            "${base_url}/resources/${id}/items"]
        }
        return work_map

    }

    def setHasItems(bool = false) {
        hasItems = bool
    }

}
