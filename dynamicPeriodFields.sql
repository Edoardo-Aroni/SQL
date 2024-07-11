-- Dynamic period values calculated with subquery factorying --
-- calculating this FY beginning period --
WITH accounting_period_subquery AS (
    SELECT 
        accountingPeriod.id,
        accountingPeriod.periodname,
        CASE
            WHEN TO_CHAR(SYSDATE, 'MM') IN ('01', '02', '03', '04', '05', '06', '07', '08', '09') 
            THEN 'Oct ' || TO_CHAR(ADD_MONTHS(SYSDATE, -10), 'YYYY') 
            ELSE 'Oct ' || TO_CHAR(SYSDATE, 'YYYY') 
        END AS target_periodname
    FROM accountingPeriod
),
-- calculating the current period ---
current_period as (
SELECT id
FROM accountingPeriod
WHERE SYSDATE BETWEEN startdate AND enddate
AND isYear='F'
AND isquarter='F')

SELECT
  subsidiary.name AS Subsidiary,
  CASE 
    WHEN transaction.postingperiod < accounting_period_subquery.id THEN 
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
  LEFT JOIN accounting_period_subquery 
    ON accounting_period_subquery.periodname = accounting_period_subquery.target_periodname
WHERE 
  account.accttype IN (
    'AcctPay', 'AcctRec', 'Bank', 'COGS', 'CredCard', 'DeferExpense', 'DeferRevenue',
    'Equity', 'Expense', 'FixedAsset', 'Income', 'LongTermLiab', 'OthAsset',
    'OthCurrAsset', 'OthCurrLiab', 'OthExpense', 'OthIncome', 'UnbilledRec'
  )
  AND transaction.posting = 'T'
  AND transactionLine.subsidiary = '21'
  AND transaction.postingperiod <= (select id from current_period)
GROUP BY
  subsidiary.name,
  CASE 
    WHEN transaction.postingperiod < accounting_period_subquery.id THEN 
      CASE 
        WHEN account.accttype IN ('Income', 'Cost of Goods Sold', 'Expense', 'Other Expense', 'Other Income') THEN 'Retained Earnings'
        ELSE BUILTIN.DF(TransactionAccountingLine.account)
      END 
    ELSE BUILTIN.DF(TransactionAccountingLine.account)
  END,
  BUILTIN.DF(transactionLine.class),
  BUILTIN.DF(transactionLine.department)
HAVING SUM(NVL(TransactionAccountingLine.debit, 0) - NVL(TransactionAccountingLine.credit, 0)) <> 0



