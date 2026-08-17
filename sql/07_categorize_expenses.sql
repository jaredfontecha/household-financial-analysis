-- Here I want to take our previously organized data by merchandise and categorize them into general spending labels

-- Add column
ALTER TABLE clean.transactions
ADD COLUMN IF NOT EXISTS spending_category TEXT;

-- Categorize spending labels
UPDATE clean.transactions
SET spending_category =
    CASE
        WHEN merchant_standardized IN ('Costco', 'Trader Joe''s', 'Smith''s')
            THEN 'Groceries'

        WHEN merchant_standardized IN ('DoorDash', 'Chipotle', 'Yard House')
            THEN 'Dining'

        WHEN merchant_standardized IN ('Cox Communications', 'NV Energy', 'Southwest Gas')
            THEN 'Utilities'

        WHEN merchant_standardized IN ('Uber', 'Shell', 'Chevron')
            THEN 'Transportation'

        WHEN merchant_standardized IN ('Amazon', 'Target', 'Nike', 'CVS', 'Walgreens')
            THEN 'Shopping'

        WHEN merchant_standardized IN ('Netflix', 'Spotify', 'AMC Theatres')
            THEN 'Entertainment'

        WHEN merchant_standardized IN ('Airbnb', 'Marriott', 'Southwest Airlines')
            THEN 'Travel'

        WHEN UPPER(description_raw) LIKE '%RENT%'
            THEN 'Housing'

        WHEN merchant_standardized = 'Las Vegas Athletic Club'
            THEN 'Fitness'

        ELSE spending_category
    END
WHERE transaction_type = 'expense';

-- See how much was spent in each category
SELECT
    spending_category,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense'
GROUP BY spending_category
ORDER BY total_amount;

-- Make sure there are no "uncategorized" rows (yup we good)
SELECT
    COUNT(*) AS uncategorized_expenses
FROM clean.transactions
WHERE duplicate_rank = 1
  AND transaction_type = 'expense'
  AND spending_category IS NULL;