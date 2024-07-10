SELECT
  subsidiary.name AS Subsidiary,
  CASE 
    WHEN transaction.postingperiod < (
        SELECT accountingPeriod.id 
        FROM accountingPeriod 
        JOIN (
            SELECT 
                CASE
                    WHEN TO_CHAR(SYSDATE, 'MM') IN ('01', '02', '03', '04', '05', '06', '07', '08', '09') 
                    THEN 'Oct ' || TO_CHAR(ADD_MONTHS(SYSDATE, -10), 'YYYY') 
                    ELSE 'Oct ' || TO_CHAR(SYSDATE, 'YYYY') 
                END AS result 
            FROM dual
        ) AS subquery
        ON accountingPeriod.periodname = subquery.result
    ) THEN 
      CASE 
        WHEN account.accttype IN ('Income', 'Cost of Goods Sold', 'Expense', 'Other Expense', 'Other Income') THEN 'Retained Earnings'
        ELSE BUILTIN.DF(TransactionAccountingLine.account)
      END 
    ELSE BUILTIN.DF(TransactionAccountingLine.account)
  END AS account,
  BUILTIN.DF(transactionLine.class) AS class,
  BUILTIN.DF(transactionLine.department) AS functional_activity,
  SUM(NVL(TransactionAccountingLine.debit, 0) - NVL(TransactionAccountingLine.credit, 0)) AS amount
FROM 
  transaction
  JOIN transactionLine ON transaction.id = transactionLine.transaction
  JOIN subsidiary ON transactionLine.subsidiary = subsidiary.id
  JOIN TransactionAccountingLine ON transactionLine.transaction = TransactionAccountingLine.transaction
                                 AND transactionLine.id = TransactionAccountingLine.transactionline
  LEFT JOIN account ON TransactionAccountingLine.account = account.id
WHERE 
  account.accttype IN (
    'AcctPay', 'AcctRec', 'Bank', 'COGS', 'CredCard', 'DeferExpense', 'DeferRevenue',
    'Equity', 'Expense', 'FixedAsset', 'Income', 'LongTermLiab', 'OthAsset',
    'OthCurrAsset', 'OthCurrLiab', 'OthExpense', 'OthIncome', 'UnbilledRec'
  )
  AND transaction.posting = 'T'
  AND transactionLine.subsidiary = '7'
  AND transaction.postingperiod <= '333'
GROUP BY
  subsidiary.name,
  CASE 
    WHEN transaction.postingperiod < (
        SELECT accountingPeriod.id 
        FROM accountingPeriod 
        JOIN (
            SELECT 
                CASE
                    WHEN TO_CHAR(SYSDATE, 'MM') IN ('01', '02', '03', '04', '05', '06', '07', '08', '09') 
                    THEN 'Oct ' || TO_CHAR(ADD_MONTHS(SYSDATE, -10), 'YYYY') 
                    ELSE 'Oct ' || TO_CHAR(SYSDATE, 'YYYY') 
                END AS result 
            FROM dual
        ) AS subquery
        ON accountingPeriod.periodname = subquery.result
    ) THEN 
      CASE 
        WHEN account.accttype IN ('Income', 'Cost of Goods Sold', 'Expense', 'Other Expense', 'Other Income') THEN 'Retained Earnings'
        ELSE BUILTIN.DF(TransactionAccountingLine.account)
      END 
    ELSE BUILTIN.DF(TransactionAccountingLine.account)
  END,
  BUILTIN.DF(transactionLine.class),
  BUILTIN.DF(transactionLine.department)
HAVING SUM(NVL(TransactionAccountingLine.debit, 0) - NVL(TransactionAccountingLine.credit, 0)) <> 0;
