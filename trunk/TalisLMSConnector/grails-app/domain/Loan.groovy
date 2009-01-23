import java.sql.Timestamp
class Loan {
    Integer itemId
    Integer borrowerId
    Boolean currentLoan
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
}
