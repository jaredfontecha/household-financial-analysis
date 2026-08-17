-- Here I want to do more financial analysis. First looking at monthly income vs. monthly expenses

-- Group transactions by month. Add up expenses vs income and make them positive values.
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') AS month,
    SUM(CASE
        WHEN transaction_type = 'income' THEN amount
        ELSE 0
    END) AS total_income,
    SUM(CASE
        WHEN transaction_type = 'expense' THEN ABS(amount)
        ELSE 0
    END) AS total_expenses,
    
    -- Calculate net cash flow (income - expense)
	SUM(CASE
	    WHEN transaction_type = 'income' THEN amount
	    ELSE 0
	END)
	-
	SUM(CASE
	    WHEN transaction_type = 'expense' THEN ABS(amount)
	    ELSE 0
	END) AS net_cash_flow,
	    
	-- Calculate savings rate: what % of income is left after expenses
	-- Formula: (income - expenses)/income * 100
	ROUND(
	    (
	        SUM(CASE
	            WHEN transaction_type = 'income' THEN amount
	            ELSE 0
	        END)
	        -
	        SUM(CASE
	            WHEN transaction_type = 'expense' THEN ABS(amount)
	            ELSE 0
	        END)
	    )
	    / --nullif(value,0) treats it as null instead of making it 0 so you don't divide by 0 in formula
	    NULLIF(
	        SUM(CASE
	            WHEN transaction_type = 'income' THEN amount
	            ELSE 0
	        END),
	        0
	    )
	    * 100,
	    2
	) AS savings_rate_pct

FROM clean.transactions
WHERE duplicate_rank = 1
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY month;

-- See what categories are doing the most damage
-- Create column for transaction count, spend sum, and avg spent
SELECT
    spending_category,
    COUNT(*) AS transaction_count,
    SUM(ABS(amount)) AS total_spent,
    ROUND(AVG(ABS(amount)), 2) AS average_transaction,
    SUM(ABS(amount)) AS total_spent,
    -- Calculate percent of each category to total
    ROUND( 
        SUM(ABS(amount))
        /
        SUM(SUM(ABS(amount))) OVER ()
        * 100,
        2
    ) AS percent_of_total_spending
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense'
GROUP BY spending_category
ORDER BY total_spent DESC;

-- See which  merchants received the most money
SELECT
    merchant_standardized,
    spending_category,
    COUNT(*) AS transaction_count,
    SUM(ABS(amount)) AS total_spent,
    ROUND(AVG(ABS(amount)), 2) AS average_transaction
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense'
GROUP BY merchant_standardized, spending_category
ORDER BY total_spent DESC;

-- I want to see if spending is consistent across months. 
-- Calculate monthly spending by category.
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') AS month,
    spending_category,
    SUM(ABS(amount)) AS total_spent
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense'
GROUP BY
    TO_CHAR(transaction_date, 'YYYY-MM'),
    spending_category
ORDER BY
    month,
    total_spent DESC;

-- Find the highest spending months
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM') AS month,
    SUM(ABS(amount)) AS total_spent
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense'
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY total_spent DESC;

-- From the previous chart, March is the highest spending month. I want to see why.
-- Calculate what drove the highest spending in March
SELECT
    spending_category,
    SUM(ABS(amount)) AS total_spent
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense'
  AND TO_CHAR(transaction_date, 'YYYY-MM') = '2025-03'
GROUP BY spending_category
ORDER BY total_spent DESC;

-- SUMMARY: Important stats for later:
-- Calculate annual executive summary metrics
SELECT
    SUM(CASE
        WHEN transaction_type = 'income' THEN amount
        ELSE 0
    END) AS annual_income,

    SUM(CASE
        WHEN transaction_type = 'expense' THEN ABS(amount)
        ELSE 0
    END) AS annual_expenses,

    SUM(CASE
        WHEN transaction_type = 'income' THEN amount
        ELSE 0
    END)
    -
    SUM(CASE
        WHEN transaction_type = 'expense' THEN ABS(amount)
        ELSE 0
    END) AS annual_net_cash_flow,

    ROUND(
        SUM(CASE
            WHEN transaction_type = 'expense' THEN ABS(amount)
            ELSE 0
        END) / 12,
        2
    ) AS average_monthly_spending

FROM clean.transactions
WHERE duplicate_rank = 1;


