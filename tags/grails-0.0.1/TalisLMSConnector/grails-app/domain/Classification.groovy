class Classification {
    String classNumber
    static mapping = {
        table 'CLASSIFICATION'
        version false
        columns {
            id column: 'CLASS_ID'
            classNumber column: 'CLASS_NUMBER'
        }
    }
}
