import java.sql.Timestamp
class Loan {
    Long itemId
    Long borrowerId
    String currentLoan
    Timestamp created
    Timestamp duedate
    Integer state
    Integer loanType
    static mapping = {
       table 'LOAN'
       version false
        columns {
            id column: 'LOAN_ID'
            itemId column: 'ITEM_ID'
            borrowerId column: 'BORROWER_ID'
            currentLoan column: 'CURRENT_LOAN'
            created column: 'CREATE_DATE'
            duedate column: 'DUE_DATE'
            state column: 'STATE'
            loanType column: 'LOAN_TYPE'

        }

    }

    static def checkItemAvailability(itemList) {
        def items = [:]
        itemList.each {
            items[it.id] = it
        }


    }

    static def findCurrentLoansFromItemList(itemsList) {
        def items = [:]
        itemsList.each {
            items[it.id] = it
        }
        def c = Loan.createCriteria()        
        def loans = c.list {
            "in"("itemId",items.keySet().toList())
            and{eq("currentLoan",'T')}
        }
        for(loan in loans) {
            items[loan.itemId].onLoan = true
            items[loan.itemId].dateAvailable = loan.duedate
            items[loan.itemId].borrowerId = loan.borrowerId
        }
    }

    static def setHasItemsFromActorsList(actorsList) {
        def actors = [:]
        actorsList.each {
            actors[it.id] = it
        }
        def c = Loan.createCriteria()
        def loans = c.list {
            "in"("borrowerId",actors.keySet().toList())
            and{eq("currentLoan",'T')}
        }
        for(loan in loans) {
            actors[loan.borrowerId].hasItems = true
        }
    }

    static def findItemsFromBorrowerIds(borrowerIds) {
        def itemIds = []
        def c = Loan.createCriteria()
        def loans = c.list {
            "in"("borrowerId",borrowerIds)
            and{eq("currentLoan",'T')}
        }
        for(loan in loans) {
            itemIds << loan.itemId
        }
        def items = Item.getAll(itemIds)
        def itemMap = [:]
        items.each {
            itemMap[it.id] = it
        }
        for(loan in loans) {
            itemMap[loan.itemId].onLoan = true
            itemMap[loan.itemId].dateAvailable = loan.duedate
            itemMap[loan.itemId].borrowerId = loan.borrowerId
            if(!itemMap[loan.itemId].via['actors']) { itemMap[loan.itemId].via['actors']=[] }
            itemMap[loan.itemId].via['actors'] << loan.borrowerId
        }
        return items
    }

}
