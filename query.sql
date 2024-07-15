WITH beginning_period AS (
    SELECT 
        enddate,
        CASE
        WHEN TO_CHAR(CURRENT_DATE, 'MM') > 10 
        THEN TO_DATE(CONCAT(TO_CHAR(CURRENT_DATE, 'YYYY'), '-10-01'), 'YYYY-MM-DD')
        ELSE TO_DATE(CONCAT(TO_CHAR(CURRENT_DATE, 'YYYY') - 1, '-10-01'), 'YYYY-MM-DD')
        END AS firstDay
    FROM 
        accountingPeriod
)


    SELECT 
        s.id AS Subsidiary_ID,
        s.name AS Subsidiary_Name,
        CASE
            WHEN ap.enddate < bp.firstDay
            THEN
                CASE
                    WHEN a.accttype IN ('Income', 'Cost of Goods Sold', 'Expense', 'Other Expense', 'Other Income')
                    THEN 'Retained Earnings'
                    ELSE a.acctnumber
                END
            ELSE a.acctnumber
        END AS "Account",
        cl.externalid AS "Class",
        d.name AS Functional_Activity,
        SUM(NVL(tl.debitforeignamount, 0) - NVL(tl.creditforeignamount, 0)) AS Amount
    FROM
        transactionline tl
    JOIN
        "transaction" t ON tl.transaction = t.id
    JOIN
        transactionaccountingline tal ON tl.id = tal.transactionline AND t.id = tal."transaction"
    JOIN
        accountingperiod ap ON t.postingperiod = ap.id
    JOIN
        account a ON tal.account = a.id
    JOIN
        subsidiary s ON tl.subsidiary = s.id
    JOIN
        classification cl ON tl.class = cl.id
    JOIN
        department d ON tl.department = d.id
    LEFT JOIN 
        beginning_period bp ON ap.enddate = bp.enddate
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
        AND a.accttype IN (
            'Bank', 'Accounts Receivable', 'Other Current Asset', 'Other Asset',
            'Accounts Payable', 'Credit Card', 'Other Current Liability', 'Long Term Liability',
            'Equity', 'Income', 'Cost of Goods Sold', 'Expenses', 'Other Income', 'Other Expenses',
            'Deferred Revenue', 'Deferred Expense', 'Unbilled Receivable'
        )
    GROUP BY
        s.id,
        s.name,
        CASE
            WHEN ap.enddate < bp.firstDay
            THEN
                CASE
                    WHEN a.accttype IN ('Income', 'Cost of Goods Sold', 'Expense', 'Other Expense', 'Other Income')
                    THEN 'Retained Earnings'
                    ELSE a.acctnumber
                END
            ELSE a.acctnumber
        END,
        cl.externalid,
        d.name
    ORDER BY
        "Account",
        "Class",
        "Subsidiary_ID"



