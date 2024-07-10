SELECT 
  subsidiary.name AS Subsidiary,
  CASE 
    WHEN transaction.postingperiod < '323' THEN 
      CASE 
        WHEN account.accttype IN ('Income', 'Cost of Goods Sold', 'Expense', 'Other Expense', 'Other Income') THEN 'Retained Earnings'
        ELSE BUILTIN.DF(TransactionAccountingLine.account)
      END 
    ELSE BUILTIN.DF(TransactionAccountingLine.account)
  END AS account,
  BUILTIN.DF(transactionLine.class) AS class,
  BUILTIN.DF(transactionLine.department) AS functional_activity,
  SUM(NVL(TransactionAccountingLine.debit,0)-NVL(TransactionAccountingLine.credit,0)) AS amount
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
  AND transactionLine.subsidiary IN ('21')
  AND transaction.postingperiod <= '333'
GROUP BY
  subsidiary.name,
  CASE 
    WHEN transaction.postingperiod < '323' THEN 
      CASE 
        WHEN account.accttype IN ('Income', 'Cost of Goods Sold', 'Expense', 'Other Expense', 'Other Income') THEN 'Retained Earnings'
        ELSE BUILTIN.DF(TransactionAccountingLine.account)
      END 
    ELSE BUILTIN.DF(TransactionAccountingLine.account)
  END,
  BUILTIN.DF(transactionLine.class),
  BUILTIN.DF(transactionLine.department)
  HAVING SUM(NVL(TransactionAccountingLine.debit,0)-NVL(TransactionAccountingLine.credit,0)) <> 0




  