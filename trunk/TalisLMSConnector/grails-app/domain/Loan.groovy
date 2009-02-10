import java.sql.Timestamp
class Loan {
    Integer itemId
    Integer borrowerId
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
            items[it.id.intValue()] = it
        }


    }

    static def findCurrentLoansFromItemList(itemsList) {
        def items = [:]
        itemsList.each {
            items[it.id.toInteger()] = it
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

}
