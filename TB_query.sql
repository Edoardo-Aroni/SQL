WITH beginning_period AS (
    SELECT 
        CASE
         WHEN TO_CHAR(CURRENT_DATE, 'MM') > 9 
         THEN TO_DATE(CONCAT(TO_CHAR(CURRENT_DATE, 'YYYY'), '-10-01'), 'YYYY-MM-DD')
         ELSE TO_DATE(CONCAT(TO_CHAR(CURRENT_DATE, 'YYYY') - 1, '-10-01'), 'YYYY-MM-DD')
        END AS fyfirstDay -- --Start of the fiscal year
        , TO_CHAR(TO_DATE(1099 || '-' || LPAD(10, 2, '0') || '-01', 'YYYY-MM-DD'), 'DD/MM/YYYY') as fromdate --pass in variable from OneStream
        , TO_CHAR(TO_DATE(2024 || '-' || LPAD(3, 2, '0') || '-01', 'YYYY-MM-DD'), 'DD/MM/YYYY') as todate --pass in variable from OneStream
    FROM 
        dual 
)
SELECT 
 Subsidiary_ID,
 Subsidiary_Name,
 Account,
 Class,
 Account_Name,
 Functional_Activity,
 SUM(Amount) as TotalAmount
FROM (
 SELECT 
  s.id AS Subsidiary_ID,
  s.name AS Subsidiary_Name,
     CASE
   WHEN ap.enddate < bp.fyfirstDay
         THEN
             CASE
    WHEN a.accttype IN ('Income', 'COGS', 'Expense', 'OthExpense', 'OthIncome')
                 THEN 'Retained Earnings'
    ELSE a.acctnumber
   END
   ELSE a.acctnumber
  END AS Account,
  CASE
   WHEN ap.enddate < bp.fyfirstDay
         THEN
             CASE
    WHEN a.accttype IN ('Income', 'COGS', 'Expense', 'OthExpense', 'OthIncome')
                 THEN 'Retained Earnings'
    ELSE a.fullname
   END
   ELSE a.fullname
  END AS Account_Name,
  cl.externalid AS 'Class',
  d.name AS Functional_Activity,
  NVL(tal.debit, 0) - NVL(tal.credit, 0) as Amount
 FROM
  transactionline tl
 JOIN
         transaction t ON
  tl.transaction = t.id
 JOIN
         transactionaccountingline tal ON
  tl.id = tal.transactionline
  AND t.id = tal.transaction
 JOIN
         accountingperiod ap ON
  t.postingperiod = ap.id
 JOIN
         account a ON
  tal.account = a.id
 JOIN
         subsidiary s ON
  tl.subsidiary = s.id
 LEFT JOIN
         classification cl ON
  tl.class = cl.id
 LEFT JOIN
         department d ON
  tl.department = d.id
 LEFT JOIN 
        beginning_period bp ON 
        1=1
 WHERE
  t.posting = 'T'
  AND s.name NOT IN (
             'Lithium Hangar Holdco', 'Lithium Maggotts Midco Limited', 'Lithium Becketts Bidco Limited',
             'EII US. INC', 'Euromoney Global Ltd Shanghai Representative Office', 'Euromoney Group Ltd',
             'Euromoney Holdings US Inc', 'Fastmarkets (Singapore) Pte Ltd', 'Fastmarkets Bulgaria EOOD',
             'Fastmarkets Global Ltd', 'Fastmarkets Group Limited', 'Fastmarkets Holdings US Inc.',
            'Fastmarkets US LLC', 'FBA Oy - Finland', 'FOEX Indexes Oy', 'Metal Bulletin Holdings LLC',
             'RISI Asia (Hong Kong) Limited', 'RISI Consulting Beijing Co Ltd', 'RISI Consultoria',
             'RISI Inc', 'RISI Sprl', 'Shanghai Leadway E-Commerce Co Ltd'
        )
  AND a.accttype IN ( 'AcctPay', 'AcctRec', 'Bank', 'COGS', 'CredCard', 'DeferExpense', 'DeferRevenue', 'Equity', 'Expense', 'FixedAsset', 'Income', 'LongTermLiab', 'OthAsset', 'OthCurrAsset', 'OthCurrLiab', 'OthExpense', 'OthIncome', 'UnbilledRec'
   )
 and ap.enddate >= NVL(bp.fromdate,TO_DATE('01/10/1900','DD/MM/YYYY'))
 and ap.enddate <= NVL(bp.todate,fyfirstDay)
  ) as MainTable
GROUP BY
 Subsidiary_ID,
 Subsidiary_Name,
 Account,
 Account_Name,
 Class,
 Functional_Activity
HAVING
 SUM(Amount) != 0
ORDER BY
 Account,
 Class,
 Subsidiary_ID