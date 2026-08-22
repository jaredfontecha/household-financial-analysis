-- Create new column
ALTER TABLE clean.transactions
ADD COLUMN IF NOT EXISTS transaction_type TEXT;

-- Categorize income
UPDATE clean.transactions
SET transaction_type = 'income'
WHERE UPPER(description_raw) LIKE '%PAYROLL%'
   OR UPPER(description_raw) LIKE '%FREELANCE DESIGN PAYMENT%';

-- Categorize transfer
UPDATE clean.transactions
SET transaction_type = 'transfer'
WHERE UPPER(description_raw) like '%TRANSFER TO CAPITAL ONE%'
   OR UPPER(description_raw) LIKE '%TRANSFER TO CHASE CARD%'
   OR UPPER(description_raw) LIKE '%MOBILE PAYMENT%'
   OR UPPER(description_raw) LIKE '%ONLINE PAYMENT THANK YOU%';

-- Categorize refunds
UPDATE clean.transactions
SET transaction_type = 'refund'
WHERE UPPER(description_raw) LIKE '%REFUND%'

-- Categorize Target returns as refunds
UPDATE clean.transactions
SET transaction_type = 'refund'
WHERE UPPER(description_raw) LIKE '%TARGET RETURN%';

-- Verify Target returns are now classified as refunds
SELECT
    description_raw,
    transaction_type,
    amount
FROM clean.transactions
WHERE UPPER(description_raw) LIKE '%TARGET RETURN%'
  AND duplicate_rank = 1;

-- Recalculate annual expenses after refund fix
SELECT
    ABS(SUM(amount)) AS annual_spending
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense';

-- Categorize everything else unassigned
UPDATE clean.transactions
SET transaction_type = 'expense'
WHERE transaction_type IS NULL;

-- VERIFY count above is correct
SELECT
    transaction_type,
    COUNT(*) AS transaction_count
FROM clean.transactions
GROUP BY transaction_type
ORDER BY transaction_count DESC;

-- VERIFY money count above is correct
SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM clean.transactions
WHERE duplicate_rank = 1
GROUP BY transaction_type
ORDER BY transaction_type;

