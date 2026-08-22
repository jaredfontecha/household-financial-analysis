# Load debt and account data from PostgreSQL into pandas
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql+psycopg2://Jared@localhost:5432/household_finance"
)

debts = pd.read_sql(
    "SELECT * FROM raw.debts;",
    engine
)

accounts = pd.read_sql(
    "SELECT * FROM raw.accounts;",
    engine
)

# Convert debt and account amount fields into numeric values
debts["balance"] = pd.to_numeric(debts["balance"])
debts["apr"] = pd.to_numeric(debts["apr"])
debts["minimum_payment"] = pd.to_numeric(debts["minimum_payment"])

accounts["opening_balance"] = pd.to_numeric(accounts["opening_balance"])

# Calculate total debt, minimum payments, and weighted average APR
total_debt = debts["balance"].sum()
total_minimum_payments = debts["minimum_payment"].sum()

weighted_average_apr = (
    (debts["balance"] * debts["apr"]).sum()
    / total_debt
    * 100
)

# Compare credit card accounts against the debt table to find missing debt balances
credit_card_accounts = accounts[
    accounts["account_type"] == "credit_card"
].copy()

credit_card_accounts["account_balance"] = (
    credit_card_accounts["opening_balance"].abs()
)

debt_credit_cards = debts[
    debts["debt_type"] == "credit_card"
][["lender", "balance"]].copy()

credit_card_reconciliation = credit_card_accounts.merge(
    debt_credit_cards,
    left_on="institution",
    right_on="lender",
    how="left"
)

credit_card_reconciliation["reconciliation_status"] = (
    credit_card_reconciliation["balance"]
    .isna()
    .map({
        True: "Missing from debt schedule",
        False: "Matched"
    })
)

# Calculate adjusted total debt including credit cards missing from the debt schedule
missing_credit_card_debt = credit_card_reconciliation.loc[
    credit_card_reconciliation["reconciliation_status"] == "Missing from debt schedule",
    "account_balance"
].sum()

adjusted_total_debt = total_debt + missing_credit_card_debt

# Calculate checking cash, cash-to-debt ratio, and net liquid position
checking_cash = accounts.loc[
    accounts["account_type"] == "checking",
    "opening_balance"
].sum()

cash_to_debt_ratio = (
    checking_cash
    / adjusted_total_debt
    * 100
)

net_liquid_position = (
    checking_cash
    - adjusted_total_debt
)

# Create debt payoff priority tables using avalanche and snowball methods
avalanche_priority = (
    debts.sort_values("apr", ascending=False)
    .reset_index(drop=True)
)

snowball_priority = (
    debts.sort_values("balance", ascending=True)
    .reset_index(drop=True)
)

# Estimate annual interest cost for each listed debt
debts["estimated_annual_interest"] = (
    debts["balance"] * debts["apr"]
).round(2)

interest_cost_summary = (
    debts[
        ["lender", "debt_type", "balance", "apr", "estimated_annual_interest"]
    ]
    .sort_values("estimated_annual_interest", ascending=False)
    .reset_index(drop=True)
)

# Calculate total estimated annual interest and credit-card share of interest cost
total_estimated_interest = debts["estimated_annual_interest"].sum()

credit_card_interest = debts.loc[
    debts["debt_type"] == "credit_card",
    "estimated_annual_interest"
].sum()

credit_card_interest_share = (
    credit_card_interest
    / total_estimated_interest
    * 100
)

# Summarize how total listed debt is distributed by debt type
debt_composition = (
    debts.groupby("debt_type")["balance"]
    .sum()
    .reset_index(name="total_balance")
    .sort_values("total_balance", ascending=False)
)

debt_composition["percent_of_listed_debt"] = (
    debt_composition["total_balance"]
    / total_debt
    * 100
).round(2)

# Compare each debt type's share of principal against its share of interest cost
interest_by_type = (
    debts.groupby("debt_type")
    .agg(
        total_balance=("balance", "sum"),
        estimated_annual_interest=("estimated_annual_interest", "sum")
    )
    .reset_index()
)

interest_by_type["percent_of_listed_debt"] = (
    interest_by_type["total_balance"]
    / total_debt
    * 100
).round(2)

interest_by_type["percent_of_interest_cost"] = (
    interest_by_type["estimated_annual_interest"]
    / total_estimated_interest
    * 100
).round(2)

# Calculate monthly debt-payment burden as a percentage of household income
transactions = pd.read_sql(
    """
    SELECT *
    FROM clean.transactions
    WHERE duplicate_rank = 1;
    """,
    engine
)

annual_income = transactions.loc[
    transactions["transaction_type"] == "income",
    "amount"
].sum()

average_monthly_income = annual_income / 12

debt_payment_burden = (
    total_minimum_payments
    / average_monthly_income
    * 100
)

# Calculate adjusted debt-to-income ratio
debt_to_income_ratio = (
    adjusted_total_debt
    / annual_income
    * 100
)

# Calculate how many months of spending the household could cover with checking cash
expenses = transactions[
    transactions["transaction_type"] == "expense"
].copy()

total_annual_spending = abs(
    expenses["amount"].sum()
)

average_monthly_spending = total_annual_spending / 12

essential_categories = [
    "Housing",
    "Utilities",
    "Groceries",
    "Transportation"
]

essential_annual_spending = abs(
    expenses.loc[
        expenses["spending_category"].isin(essential_categories),
        "amount"
    ].sum()
)

average_monthly_essential_spending = (
    essential_annual_spending / 12
)

all_spending_runway_months = (
    checking_cash / average_monthly_spending
)

essential_runway_months = (
    checking_cash / average_monthly_essential_spending
)

# Calculate what percentage of one year of essential spending is covered by checking cash
checking_vs_annual_essentials = (
    checking_cash
    / essential_annual_spending
    * 100
)

# Final outputs for debt and liquidity analysis
print("\n=== DEBT & LIQUIDITY ANALYSIS SUMMARY ===")

print("\nAdjusted debt summary:")
print("Listed debt:", round(total_debt, 2))
print("Missing credit card debt:", round(missing_credit_card_debt, 2))
print("Adjusted total known debt:", round(adjusted_total_debt, 2))

print("\nCredit card reconciliation:")
print(
    credit_card_reconciliation[
        [
            "account_name",
            "institution",
            "account_balance",
            "balance",
            "reconciliation_status"
        ]
    ]
)

print("\nDebt principal vs interest burden:")
print(interest_by_type)

print("\nAvalanche payoff priority:")
print(avalanche_priority[["lender", "balance", "apr"]])

print("\nSnowball payoff priority:")
print(snowball_priority[["lender", "balance", "apr"]])

print("\nFinancial health metrics:")
print("Checking cash:", round(checking_cash, 2))
print("Cash-to-debt ratio:", round(cash_to_debt_ratio, 2), "%")
print("Net liquid position:", round(net_liquid_position, 2))
print("Debt payment burden:", round(debt_payment_burden, 2), "%")
print("Debt-to-income ratio:", round(debt_to_income_ratio, 2), "%")
print("All-spending runway:", round(all_spending_runway_months, 2), "months")
print("Essential-spending runway:", round(essential_runway_months, 2), "months")