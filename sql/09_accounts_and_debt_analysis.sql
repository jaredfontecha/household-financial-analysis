-- I want to look more into the accounts and debt.
-- First off I want to understand the distribution of funds across accounts.

-- Review all household accounts
SELECT
    account_name,
    account_type,
    opening_balance
FROM raw.accounts;
-- There are 5 accounts: 2 checking and 3 credit cards

-- Total balances by account type (checking vs credit)
SELECT
    account_type,
    SUM(opening_balance::NUMERIC) AS total_balance
FROM raw.accounts
GROUP BY account_type
ORDER BY account_type;

-- Review all household debts
SELECT
    debt_id,
    debt_type,
    lender,
    balance,
    apr,
    minimum_payment,
    remaining_payments
FROM raw.debts;

-- Summarize total debt and monthly minimum payments
SELECT
    SUM(balance::NUMERIC) AS total_debt,
    SUM(minimum_payment::NUMERIC) AS total_minimum_payments
FROM raw.debts;

-- Compare monthly debt payments to average monthly income
SELECT
    ROUND(
        1443
        /
        (174923.04 / 12)
        * 100,
        2
    ) AS debt_payment_burden_pct;

-- Convert the above equation into a formula that can pull values directly from table.
SELECT
    ROUND(
        (
            SELECT SUM(minimum_payment::NUMERIC)
            FROM raw.debts
        )
        /
        (
            SELECT SUM(amount) / 12
            FROM clean.transactions
            WHERE duplicate_rank = 1
              AND transaction_type = 'income'
        )
        * 100,
        2
    ) AS debt_payment_burden_pct;

-- Calculate weighted average APR across all listed debts
-- Essentially: what interest rate are they effectively paying on average, weighted by how large each balance is
SELECT
    ROUND(
        SUM(balance::NUMERIC * apr::NUMERIC)
        /
        SUM(balance::NUMERIC)
        * 100,
        2
    ) AS weighted_average_apr_pct
FROM raw.debts;

-- Estimate annual interest cost based on current balances and APRs
SELECT
    ROUND(
        SUM(balance::NUMERIC * apr::NUMERIC),
        2
    ) AS estimated_annual_interest_cost
FROM raw.debts;

-- Summarize debt balances by debt type to see how total debt is divided
SELECT
    debt_type,
    SUM(balance::NUMERIC) AS total_balance,
    ROUND(
        SUM(balance::NUMERIC)
        /
        SUM(SUM(balance::NUMERIC)) OVER ()
        * 100,
        2
    ) AS percent_of_total_debt
FROM raw.debts
GROUP BY debt_type
ORDER BY total_balance DESC;

-- I want to see which debt is actually the most expensive by comparing annual interest cost
-- Rank individual debts by estimated annual interest cost
SELECT
    lender,
    debt_type,
    balance::NUMERIC AS balance,
    ROUND(apr::NUMERIC * 100, 2) AS apr_pct,
    ROUND(
        balance::NUMERIC * apr::NUMERIC,
        2
    ) AS estimated_annual_interest
FROM raw.debts
ORDER BY estimated_annual_interest DESC;

-- Rank debts by APR for debt-avalanche payoff priority
-- Avalanche = pay off highest interest first (helps mathmatically)
SELECT
    lender,
    debt_type,
    balance::NUMERIC AS balance,
    ROUND(apr::NUMERIC * 100, 2) AS apr_pct,
    minimum_payment::NUMERIC AS minimum_payment
FROM raw.debts
ORDER BY apr::NUMERIC DESC;

-- Rank debts by balance for debt-snowball payoff priority
-- Snowball = pay off lowest balance first (helps psychologically)
SELECT
    lender,
    debt_type,
    balance::NUMERIC AS balance,
    ROUND(apr::NUMERIC * 100, 2) AS apr_pct,
    minimum_payment::NUMERIC AS minimum_payment
FROM raw.debts
ORDER BY balance::NUMERIC ASC;

-- Compare available checking cash to total listed debt
-- Calculate cash-to-debt ratio
SELECT
    ROUND(
        (
            SELECT SUM(opening_balance::NUMERIC)
            FROM raw.accounts
            WHERE account_type = 'checking'
        )
        /
        (
            SELECT SUM(balance::NUMERIC)
            FROM raw.debts
        )
        * 100,
        2
    ) AS cash_to_debt_pct;

-- I noticed the accounts include a travel card that isn't included on the debt schedule
-- Compare credit card accounts against the detailed debt schedule
SELECT
    a.account_name,
    a.institution,
    ABS(a.opening_balance::NUMERIC) AS account_balance,
    d.balance::NUMERIC AS debt_schedule_balance,
    CASE
        WHEN d.lender IS NULL THEN 'Missing from debt schedule'
        WHEN ABS(a.opening_balance::NUMERIC) = d.balance::NUMERIC THEN 'Matched'
        ELSE 'Balance mismatch'
    END AS reconciliation_status
FROM raw.accounts AS a
LEFT JOIN raw.debts AS d
    ON UPPER(a.institution) = UPPER(d.lender)
WHERE a.account_type = 'credit_card';

-- Calculate adjusted total known debt, including credit card balances missing from debt schedule
SELECT
    (
        SELECT SUM(balance::NUMERIC)
        FROM raw.debts
    )
    +
    (
        SELECT SUM(ABS(a.opening_balance::NUMERIC))
        FROM raw.accounts AS a
        LEFT JOIN raw.debts AS d
            ON UPPER(a.institution) = UPPER(d.lender)
        WHERE a.account_type = 'credit_card'
          AND d.lender IS NULL
    ) AS adjusted_total_known_debt;

-- NEW Cash-to-Debt Ratio
-- Recalculate cash-to-debt ratio using adjusted known debt
SELECT
    ROUND(
        (
            SELECT SUM(opening_balance::NUMERIC)
            FROM raw.accounts
            WHERE account_type = 'checking'
        )
        /
        (
            (
                SELECT SUM(balance::NUMERIC)
                FROM raw.debts
            )
            +
            (
                SELECT SUM(ABS(a.opening_balance::NUMERIC))
                FROM raw.accounts AS a
                LEFT JOIN raw.debts AS d
                    ON UPPER(a.institution) = UPPER(d.lender)
                WHERE a.account_type = 'credit_card'
                  AND d.lender IS NULL
            )
        )
        * 100,
        2
    ) AS adjusted_cash_to_debt_pct;

-- NEW net liquid position
-- Calculate net liquid position after adjusted known debt
SELECT
    (
        SELECT SUM(opening_balance::NUMERIC)
        FROM raw.accounts
        WHERE account_type = 'checking'
    )
    -
    (
        (
            SELECT SUM(balance::NUMERIC)
            FROM raw.debts
        )
        +
        (
            SELECT SUM(ABS(a.opening_balance::NUMERIC))
            FROM raw.accounts AS a
            LEFT JOIN raw.debts AS d
                ON UPPER(a.institution) = UPPER(d.lender)
            WHERE a.account_type = 'credit_card'
              AND d.lender IS NULL
        )
    ) AS net_liquid_position;

-- Calculate how much of total known debt is high-interest credit card debt (not including travel card)
SELECT
    SUM(balance::NUMERIC) AS credit_card_debt,
    ROUND(
        SUM(balance::NUMERIC)
        /
        (
            SELECT SUM(balance::NUMERIC)
            FROM raw.debts
        )
        * 100,
        2
    ) AS credit_card_share_of_listed_debt_pct
FROM raw.debts
WHERE debt_type = 'credit_card';

-- NEW Credit card interest share (with travel card)
-- Calculate adjusted credit card share including missing Amex balance
SELECT
    ROUND(
        (
            (
                SELECT SUM(balance::NUMERIC)
                FROM raw.debts
                WHERE debt_type = 'credit_card'
            )
            +
            (
                SELECT SUM(ABS(a.opening_balance::NUMERIC))
                FROM raw.accounts AS a
                LEFT JOIN raw.debts AS d
                    ON UPPER(a.institution) = UPPER(d.lender)
                WHERE a.account_type = 'credit_card'
                  AND d.lender IS NULL
            )
        )
        /
        (
            (
                SELECT SUM(balance::NUMERIC)
                FROM raw.debts
            )
            +
            (
                SELECT SUM(ABS(a.opening_balance::NUMERIC))
                FROM raw.accounts AS a
                LEFT JOIN raw.debts AS d
                    ON UPPER(a.institution) = UPPER(d.lender)
                WHERE a.account_type = 'credit_card'
                  AND d.lender IS NULL
            )
        )
        * 100,
        2
    ) AS adjusted_credit_card_share_pct;

-- Compare adjusted total known debt to annual income
SELECT
    ROUND(
        (
            (
                SELECT SUM(balance::NUMERIC)
                FROM raw.debts
            )
            +
            (
                SELECT SUM(ABS(a.opening_balance::NUMERIC))
                FROM raw.accounts AS a
                LEFT JOIN raw.debts AS d
                    ON UPPER(a.institution) = UPPER(d.lender)
                WHERE a.account_type = 'credit_card'
                  AND d.lender IS NULL
            )
        )
        /
        (
            SELECT SUM(amount)
            FROM clean.transactions
            WHERE duplicate_rank = 1
              AND transaction_type = 'income'
        )
        * 100,
        2
    ) AS debt_to_annual_income_pct;

-- Estimate how many months of spending checking cash could cover (if income stopped and current spending continued, how long would liquid cash take them?)
-- Formula: checking cash/avg monthly spending
SELECT
    ROUND(
        (
            SELECT SUM(opening_balance::NUMERIC)
            FROM raw.accounts
            WHERE account_type = 'checking'
        )
        /
        (
            SELECT SUM(ABS(amount)) / 12
            FROM clean.transactions
            WHERE duplicate_rank = 1
              AND transaction_type = 'expense'
        ),
        2
    ) AS months_of_spending_covered;

-- Estimate how many months of essential spending checking cash could cover
-- Only include housing, utilities, groceries, and transportation
SELECT
    ROUND(
        (
            SELECT SUM(opening_balance::NUMERIC)
            FROM raw.accounts
            WHERE account_type = 'checking'
        )
        /
        (
            SELECT SUM(ABS(amount)) / 12
            FROM clean.transactions
            WHERE duplicate_rank = 1
              AND transaction_type = 'expense'
              AND spending_category IN (
                  'Housing',
                  'Utilities',
                  'Groceries',
                  'Transportation'
              )
        ),
        2
    ) AS months_of_essential_spending_covered;

-- Convert above calculation into a percentage of the year
-- Calculate checking cash as a percentage of annual essential spending
SELECT
    ROUND(
        (
            SELECT SUM(opening_balance::NUMERIC)
            FROM raw.accounts
            WHERE account_type = 'checking'
        )
        /
        (
            SELECT SUM(ABS(amount))
            FROM clean.transactions
            WHERE duplicate_rank = 1
              AND transaction_type = 'expense'
              AND spending_category IN (
                  'Housing',
                  'Utilities',
                  'Groceries',
                  'Transportation'
              )
        )
        * 100,
        2
    ) AS checking_cash_vs_annual_essential_spending_pct;

-- Review client profile information
SELECT
    client_id,
    name,
    age,
    relationship,
    city,
    state,
    retirement_age,
    risk_tolerance
FROM raw.client_profile;

-- Calculate years remaining until each client's target retirement age
SELECT
    name,
    age::NUMERIC AS current_age,
    retirement_age::NUMERIC AS retirement_age,
    retirement_age::NUMERIC - age::NUMERIC AS years_until_retirement,
    risk_tolerance
FROM raw.client_profile
ORDER BY age::NUMERIC DESC;

-- Calculate average household years until retirement
SELECT
    ROUND(
        AVG(retirement_age::NUMERIC - age::NUMERIC),
        2
    ) AS average_years_until_retirement
FROM raw.client_profile;

-- SUMMARY
-- Create a high-level household financial health summary
SELECT
    (
        SELECT SUM(amount)
        FROM clean.transactions
        WHERE duplicate_rank = 1
          AND transaction_type = 'income'
    ) AS annual_income,

    (
        SELECT SUM(ABS(amount))
        FROM clean.transactions
        WHERE duplicate_rank = 1
          AND transaction_type = 'expense'
    ) AS annual_expenses,

    (
        SELECT SUM(opening_balance::NUMERIC)
        FROM raw.accounts
        WHERE account_type = 'checking'
    ) AS checking_cash,

    (
        (
            SELECT SUM(balance::NUMERIC)
            FROM raw.debts
        )
        +
        (
            SELECT SUM(ABS(a.opening_balance::NUMERIC))
            FROM raw.accounts AS a
            LEFT JOIN raw.debts AS d
                ON UPPER(a.institution) = UPPER(d.lender)
            WHERE a.account_type = 'credit_card'
              AND d.lender IS NULL
        )
    ) AS adjusted_total_known_debt,

    ROUND(
        AVG(retirement_age::NUMERIC - age::NUMERIC),
        2
    ) AS average_years_until_retirement

FROM raw.client_profile;