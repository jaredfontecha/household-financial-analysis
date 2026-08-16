SELECT *
FROM raw.transactions
LIMIT 20;

-- Check for missing or blank values
SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(transaction_id), '') IS NULL
    ) AS missing_transaction_id,
    
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(account_id), '') IS NULL
    ) AS missing_account_id,
    
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(transaction_date), '') IS NULL
    ) AS missing_transaction_date,
    
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(description), '') IS NULL
    ) AS missing_description,
    
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(amount), '') IS NULL
    ) AS missing_amount,
    
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(client_reported_category), '') IS NULL
    ) AS missing_category
FROM raw.transactions;


-- Find possible duplicate transactions, even with different IDs
SELECT
    account_id,
    transaction_date,
    description,
    amount,
    COUNT(*) AS times_found,
STRING_AGG(transaction_id, ', ') AS transaction_ids,
STRING_AGG(posted_date, ', ') AS posted_dates
FROM raw.transactions
GROUP BY
    account_id,
    transaction_date,
    description,
    amount
HAVING COUNT(*) > 1
ORDER BY times_found DESC;

-- Count the different transaction-date formats
SELECT
    CASE
        WHEN TRIM(transaction_date) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2} 00:00:00$'
            THEN 'YYYY-MM-DD timestamp'
        WHEN TRIM(transaction_date) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 'YYYY-MM-DD'
        WHEN TRIM(transaction_date) ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN 'M/D/YYYY'
        ELSE 'Other'
    END AS date_format,
    COUNT(*) AS row_count
FROM raw.transactions
GROUP BY date_format
ORDER BY row_count DESC;

-- Identify the different amount formats
SELECT
    CASE
        WHEN TRIM(amount) ~ '^-?[0-9]+(\.[0-9]{1,2})?$'
            THEN 'Plain number'
        WHEN TRIM(amount) ~ '^\$-?[0-9,]+(\.[0-9]{1,2})?$'
            THEN 'Dollar sign or commas'
        WHEN TRIM(amount) ~ '^\([0-9,]+(\.[0-9]{1,2})?\)$'
            THEN 'Parentheses'
        ELSE 'Other'
    END AS amount_format,
    COUNT(*) AS row_count
FROM raw.transactions
GROUP BY amount_format
ORDER BY row_count DESC;