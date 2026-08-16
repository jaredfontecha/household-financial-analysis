-- Create a separate area for cleaned data
CREATE SCHEMA IF NOT EXISTS clean;

-- Remove the cleaned table if this script was previously run
DROP TABLE IF EXISTS clean.transactions;

-- Create a cleaned copy with standardized transaction dates
CREATE TABLE clean.transactions AS
SELECT
    TRIM(transaction_id) AS transaction_id,
    TRIM(account_id) AS account_id,

    CASE
        WHEN TRIM(transaction_date) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
            THEN LEFT(TRIM(transaction_date), 10)::DATE
        WHEN TRIM(transaction_date) ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN TO_DATE(TRIM(transaction_date), 'MM/DD/YYYY')
    END AS transaction_date,

    CASE
    WHEN TRIM(posted_date) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
        THEN LEFT(TRIM(posted_date), 10)::DATE
    WHEN TRIM(posted_date) ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
        THEN TO_DATE(TRIM(posted_date), 'MM/DD/YYYY')
    END AS posted_date,

    TRIM(amount)::NUMERIC(12, 2) AS amount,
    TRIM(description) AS description_raw,
    UPPER(TRIM(currency)) AS currency,
    TRIM(source_file) AS source_file,
    NULLIF(TRIM(client_reported_category), '') AS client_reported_category,
    FALSE AS possible_duplicate,
    1 AS duplicate_rank
    FROM raw.transactions;
    
    -- Rank matching transactions and flag only the extra copies
    WITH ranked_transactions AS (
        SELECT
            transaction_id,
            ROW_NUMBER() OVER (
                PARTITION BY
                    account_id,
                    transaction_date,
                    posted_date,
                    description_raw,
                    amount
                ORDER BY transaction_id
            ) AS duplicate_rank
        FROM clean.transactions
    )
    UPDATE clean.transactions AS t
    SET
        duplicate_rank = r.duplicate_rank,
        possible_duplicate = (r.duplicate_rank > 1)
    FROM ranked_transactions AS r
    WHERE t.transaction_id = r.transaction_id;

-- Verify the cleaned dates
SELECT
    COUNT(*) AS total_rows,
    COUNT(transaction_date) AS valid_transaction_dates,
    COUNT(posted_date) AS valid_posted_dates,
    MIN(transaction_date) AS earliest_transaction_date,
    MAX(transaction_date) AS latest_transaction_date
FROM clean.transactions;

-- Verify that amounts are numeric and usable for calculations
SELECT
    PG_TYPEOF(amount) AS amount_type,
    COUNT(*) AS total_rows,
    ROUND(SUM(amount), 2) AS net_amount,
    ROUND(AVG(amount), 2) AS average_amount
FROM clean.transactions
GROUP BY PG_TYPEOF(amount);

-- Count transactions by duplicate-review status
SELECT
    possible_duplicate,
    COUNT(*) AS transaction_count
FROM clean.transactions
GROUP BY possible_duplicate
ORDER BY possible_duplicate;

-- Review transactions flagged as possible duplicates
SELECT
    transaction_id,
    account_id,
    transaction_date,
    posted_date,
    description_raw,
    amount
FROM clean.transactions
WHERE possible_duplicate = TRUE
ORDER BY
    account_id,
    transaction_date,
    description_raw,
    amount,
    transaction_id;