SELECT 
  subsidiary.name as Subsidiary,
  BUILTIN.DF(TransactionAccountingLine.account) AS account,
  BUILTIN.DF(transactionLine.class) AS class,
  BUILTIN.DF(transactionLine.department) AS functional_activity, 
  SUM(TransactionAccountingLine.amount) AS amount
FROM 
  transaction
  JOIN transactionLine ON transaction.id = transactionLine.transaction
  JOIN subsidiary ON  transactionLine.subsidiary = subsidiary.id
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
  AND transactionLine.subsidiary IN ('117')
  AND transaction.postingperiod IN (BUILTIN.PERIOD('LP', 'START', 'NOT_LAST', 'BETWEEN'))
GROUP BY
  subsidiary.name,
  BUILTIN.DF(TransactionAccountingLine.account),
  BUILTIN.DF(transactionLine.class),
  BUILTIN.DF(transactionLine.department)