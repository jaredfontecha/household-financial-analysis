CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE raw.accounts (
    account_id TEXT,
    client_id TEXT,
    account_name TEXT,
    account_type TEXT,
    institution TEXT,
    last_four TEXT,
    opening_balance TEXT
);

CREATE TABLE raw.client_profile (
    client_id TEXT,
    name TEXT,
    age TEXT,
    relationship TEXT,
    city TEXT,
    state TEXT,
    retirement_age TEXT,
    risk_tolerance TEXT
);

CREATE TABLE raw.debts (
    debt_id TEXT,
    client_id TEXT,
    debt_type TEXT,
    lender TEXT,
    balance TEXT,
    apr TEXT,
    minimum_payment TEXT,
    remaining_payments TEXT
);

CREATE TABLE raw.transactions (
    transaction_id TEXT,
    account_id TEXT,
    transaction_date TEXT,
    posted_date TEXT,
    description TEXT,
    amount TEXT,
    currency TEXT,
    source_file TEXT,
    client_reported_category TEXT
);

CREATE TABLE raw.data_dictionary (
    file TEXT,
    field TEXT,
    definition TEXT
);