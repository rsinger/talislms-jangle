class TypeStatus implements Serializable {
    Integer typeId
    Integer subType
    String name
    static mapping = {
        table 'TYPE_STATUS'
        version false
        columns {
            id composite:['typeId','subType']
            typeId column: 'TYPE_STATUS'
            subType column: 'SUB_TYPE'
            name column: 'NAME'
        }
    }
}
