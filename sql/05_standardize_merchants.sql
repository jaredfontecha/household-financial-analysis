SELECT
    description_raw,
    COUNT(*) AS transaction_count
FROM clean.transactions
WHERE duplicate_rank = 1
GROUP BY description_raw
ORDER BY transaction_count DESC, description_raw;

ALTER TABLE clean.transactions
ADD COLUMN IF NOT EXISTS merchant_standardized TEXT;

UPDATE clean.transactions
SET merchant_standardized = description_raw
WHERE merchant_standardized IS NULL;

UPDATE clean.transactions
SET merchant_standardized = 'Cox Communications'
WHERE UPPER(description_raw) LIKE '%COX COMMUNICATIONS%';

UPDATE clean.transactions
SET merchant_standardized = 'CVS'
WHERE UPPER(description_raw) LIKE '%CVS%';

UPDATE clean.transactions
SET merchant_standardized = 'Costco'
WHERE UPPER(description_raw) LIKE '%COSTCO%';

UPDATE clean.transactions
SET merchant_standardized = 'Target'
WHERE UPPER(description_raw) LIKE '%TARGET%';

UPDATE clean.transactions
SET merchant_standardized = 'Uber'
WHERE UPPER(description_raw) LIKE '%UBER%';

UPDATE clean.transactions
SET merchant_standardized = 'Nike'
WHERE UPPER(description_raw) LIKE '%NIKE%';

UPDATE clean.transactions
SET merchant_standardized = 'Netflix'
WHERE UPPER(description_raw) LIKE '%NETFLIX%';

-- If merchant has a space, you need to account for transactions w/ or w/o space
UPDATE clean.transactions
SET merchant_standardized = 'NV Energy'
WHERE UPPER(description_raw) LIKE '%NV ENERGY%'
   OR UPPER(description_raw) LIKE '%NVENERGY%';

UPDATE clean.transactions
SET merchant_standardized = 'Walgreens'
WHERE UPPER(description_raw) LIKE '%WALGREENS%';

-- For apostrophes like Trader Joe's, use two quotes to bracket separate words and apostrophe is auto placed
UPDATE clean.transactions
SET merchant_standardized = 'Trader Joe''s'
WHERE UPPER(description_raw) LIKE '%TRADER JOE%';

UPDATE clean.transactions
SET merchant_standardized = 'Airbnb'
WHERE UPPER(description_raw) LIKE '%AIRBNB%';

--I got tired and realized you can use a case statement to condense all of this into one.
UPDATE clean.transactions
SET merchant_standardized =
    CASE
        WHEN UPPER(description_raw) LIKE '%SOUTHWEST GAS%'
          OR UPPER(description_raw) LIKE '%SW GAS%'
            THEN 'Southwest Gas'

        WHEN UPPER(description_raw) LIKE '%MARRIOTT%'
            THEN 'Marriott'

        WHEN UPPER(description_raw) LIKE '%SPOTIFY%'
            THEN 'Spotify'

        WHEN UPPER(description_raw) LIKE '%SHELL%'
            THEN 'Shell'

        WHEN UPPER(description_raw) LIKE '%AMC%'
            THEN 'AMC Theatres'

        WHEN UPPER(description_raw) LIKE '%CHEVRON%'
            THEN 'Chevron'

        WHEN UPPER(description_raw) LIKE '%SOUTHWEST AIR%'
            THEN 'Southwest Airlines'

        WHEN UPPER(description_raw) LIKE '%LAS VEGAS ATHLETIC CLUB%'
          OR UPPER(description_raw) LIKE '%LVAC%'
            THEN 'Las Vegas Athletic Club'

        WHEN UPPER(description_raw) LIKE '%AMAZON%'
          OR UPPER(description_raw) LIKE '%AMZN%'
            THEN 'Amazon'

        WHEN UPPER(description_raw) LIKE '%SMITHS%'
          OR UPPER(description_raw) LIKE '%SMITH''S%'
            THEN 'Smith''s'

        WHEN UPPER(description_raw) LIKE '%CHIPOTLE%'
            THEN 'Chipotle'

        WHEN UPPER(description_raw) LIKE '%YARD HOUSE%'
            THEN 'Yard House'

        WHEN UPPER(description_raw) LIKE '%DOORDASH%'
            THEN 'DoorDash'

        ELSE merchant_standardized
    END;

--See a list of all transactions
SELECT
    merchant_standardized,
    COUNT(*) AS transaction_count
FROM clean.transactions
WHERE duplicate_rank = 1
GROUP BY merchant_standardized
ORDER BY transaction_count DESC, merchant_standardized;

-- See remaining unmodified transactions
SELECT
    description_raw,
    COUNT(*) AS transaction_count
FROM clean.transactions
WHERE duplicate_rank = 1
  AND merchant_standardized = description_raw
GROUP BY description_raw
ORDER BY transaction_count DESC, description_raw;

-- Final standardized names, not just the rows that happen to still equal "description_raw"
SELECT
    merchant_standardized,
    COUNT(*) AS transaction_count
FROM clean.transactions
WHERE duplicate_rank = 1
GROUP BY merchant_standardized
ORDER BY transaction_count DESC, merchant_standardized;