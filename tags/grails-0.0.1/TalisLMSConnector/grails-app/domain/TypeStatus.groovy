class TypeStatus implements Serializable {
    Integer typeId
    Integer subType
    String name
    static mapping = {
        table 'TYPE_STATUS'
        version false
        id composite:['typeId','subType']
        columns {            
            typeId column: 'TYPE_STATUS'
            subType column: 'SUB_TYPE'
            name column: 'NAME'
        }
    }
}
