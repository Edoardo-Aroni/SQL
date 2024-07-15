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
)
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
AND subsidiary.name NOT IN (
            'Lithium Hangar Holdco', 'Lithium Maggotts Midco Limited', 'Lithium Becketts Bidco Limited',
            'EII US. INC', 'Euromoney Global Ltd Shanghai Representative Office', 'Euromoney Group Ltd',
            'Euromoney Holdings US Inc', 'Fastmarkets (Singapore) Pte Ltd', 'Fastmarkets Bulgaria EOOD',
            'Fastmarkets Global Ltd', 'Fastmarkets Group Limited', 'Fastmarkets Holdings US Inc.',
            'Fastmarkets US LLC', 'FBA Oy - Finland', 'FOEX Indexes Oy', 'Metal Bulletin Holdings LLC',
            'RISI Asia (Hong Kong) Limited', 'RISI Consulting Beijing Co Ltd', 'RISI Consultoria',
            'RISI Inc', 'RISI Sprl', 'Shanghai Leadway E-Commerce Co Ltd'
        )
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



