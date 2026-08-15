SELECT 'accounts' AS table_name, COUNT(*) AS row_count
FROM raw.accounts

UNION ALL

SELECT 'client_profile', COUNT(*)
FROM raw.client_profile

UNION ALL

SELECT 'data_dictionary', COUNT(*)
FROM raw.data_dictionary

UNION ALL

SELECT 'debts', COUNT(*)
FROM raw.debts

UNION ALL

SELECT 'transactions', COUNT(*)
FROM raw.transactions;