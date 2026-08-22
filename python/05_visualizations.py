# Financial Analysis Visualizations
# Creates presentation-ready charts from the household spending, debt,
# liquidity, and financial health analysis for the final dashboard/report.

import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine
from pathlib import Path

# Connect Python to the PostgreSQL household finance database
engine = create_engine(
    "postgresql+psycopg2://Jared@localhost:5432/household_finance"
)

# Create a folder for the finished chart images
chart_folder = Path("dashboard/charts")
chart_folder.mkdir(parents=True, exist_ok=True)

# Load cleaned transaction data
transactions = pd.read_sql(
    "SELECT * FROM clean.transactions WHERE duplicate_rank = 1;",
    engine
)

# Load account data for liquidity calculations
accounts = pd.read_sql(
    "SELECT * FROM raw.accounts;",
    engine
)

accounts["opening_balance"] = pd.to_numeric(
    accounts["opening_balance"]
)

checking_cash = accounts.loc[
    accounts["account_type"] == "checking",
    "opening_balance"
].sum()

# Filter transaction data to expenses only
expenses = transactions[
    transactions["transaction_type"] == "expense"
].copy()

# Define categories used throughout the visualizations
essential_categories = [
    "Housing",
    "Utilities",
    "Groceries",
    "Transportation"
]

discretionary_categories = [
    "Travel",
    "Shopping",
    "Dining",
    "Entertainment",
    "Fitness"
]

# CHART 1: Build and save annual spending by category
category_spending = (
    expenses.groupby("spending_category")["amount"]
    .sum()
    .abs()
    .sort_values(ascending=False)
)

category_spending.plot(kind="bar")

plt.title("Annual Spending by Category")
plt.xlabel("Spending Category")
plt.ylabel("Annual Spending ($)")
plt.xticks(rotation=45)
plt.tight_layout()

plt.savefig(
    chart_folder / "01_annual_spending_by_category.png",
    dpi=300,
    bbox_inches="tight"
)
plt.close()

# CHART 2: Monthly spending trend
expenses["transaction_date"] = pd.to_datetime(expenses["transaction_date"])

expenses["month"] = (
    expenses["transaction_date"]
    .dt.to_period("M")
    .astype(str)
)

monthly_spending = (
    expenses.groupby("month")["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
)

plt.figure()

plt.plot(
    monthly_spending["month"],
    monthly_spending["total_spent"],
    marker="o"
)

# Add average monthly spending line to highlight unusually high months
average_monthly_spending = monthly_spending["total_spent"].mean()

plt.axhline(
    y=average_monthly_spending,
    linestyle="--",
    label=f"Average: ${average_monthly_spending:,.0f}"
)

plt.legend()

plt.title("Monthly Spending Trend")
plt.xlabel("Month")
plt.ylabel("Monthly Spending ($)")
plt.xticks(rotation=45)
plt.tight_layout()

plt.savefig(
    chart_folder / "02_monthly_spending_trend.png",
    dpi=300,
    bbox_inches="tight"
)
plt.close()

# CHART 3: Debt principal vs interest burden
debts = pd.read_sql(
    "SELECT * FROM raw.debts;",
    engine
)

debts["balance"] = pd.to_numeric(debts["balance"])
debts["apr"] = pd.to_numeric(debts["apr"])

debts["estimated_annual_interest"] = (
    debts["balance"] * debts["apr"]
)

debt_type_summary = (
    debts.groupby("debt_type")
    .agg(
        total_balance=("balance", "sum"),
        estimated_annual_interest=("estimated_annual_interest", "sum")
    )
    .reset_index()
)

debt_type_summary["principal_share"] = (
    debt_type_summary["total_balance"]
    / debt_type_summary["total_balance"].sum()
    * 100
)

debt_type_summary["interest_share"] = (
    debt_type_summary["estimated_annual_interest"]
    / debt_type_summary["estimated_annual_interest"].sum()
    * 100
)

debt_type_summary.plot(
    x="debt_type",
    y=["principal_share", "interest_share"],
    kind="bar"
)

plt.title("Debt Principal vs Interest Burden")
plt.xlabel("Debt Type")
plt.ylabel("Share of Total (%)")
plt.xticks(rotation=0)
plt.legend(["Principal Share", "Interest Cost Share"])
plt.tight_layout()

plt.savefig(
    chart_folder / "03_debt_principal_vs_interest.png",
    dpi=300,
    bbox_inches="tight"
)
plt.close()

# CHART 4: Break-even tradeoff
# Calculate break-even tradeoff data automatically from the household's data
annual_income = transactions.loc[
    transactions["transaction_type"] == "income",
    "amount"
].sum()

annual_spending = abs(expenses["amount"].sum())

annual_net_cash_flow = annual_income - annual_spending

total_discretionary_spending = abs(
    expenses.loc[
        expenses["spending_category"].isin(discretionary_categories),
        "amount"
    ].sum()
)

spending_cut_percent = list(range(10, 81, 10))

required_income_increase_percent = []

for cut_percent in spending_cut_percent:
    cut_rate = cut_percent / 100

    annual_savings = (
        total_discretionary_spending * cut_rate
    )

    remaining_deficit = abs(
        annual_net_cash_flow + annual_savings
    )

    required_income_increase = (
        remaining_deficit
        / annual_income
        * 100
    )

    required_income_increase_percent.append(
        required_income_increase
    )

plt.figure()

plt.plot(
    spending_cut_percent,
    required_income_increase_percent,
    marker="o"
)

plt.title("Break-Even Tradeoff: Spending Cuts vs Income Growth")
plt.xlabel("Discretionary Spending Cut (%)")
plt.ylabel("Required Income Increase (%)")
plt.tight_layout()

plt.savefig(
    chart_folder / "04_break_even_tradeoff.png",
    dpi=300,
    bbox_inches="tight"
)
plt.close()

# CHART 5: Essential vs discretionary spending
essential_spending = abs(
    expenses.loc[
        expenses["spending_category"].isin(essential_categories),
        "amount"
    ].sum()
)

discretionary_spending = abs(
    expenses.loc[
        expenses["spending_category"].isin(discretionary_categories),
        "amount"
    ].sum()
)

spending_mix = pd.Series(
    {
        "Essential": essential_spending,
        "Discretionary": discretionary_spending
    }
)

plt.figure()

spending_mix.plot(
    kind="pie",
    autopct="%1.1f%%",
    ylabel=""
)

plt.title("Essential vs Discretionary Spending")
plt.tight_layout()

plt.savefig(
    chart_folder / "05_essential_vs_discretionary.png",
    dpi=300,
    bbox_inches="tight"
)
plt.close()

# CHART 6: Checking cash runway
average_monthly_spending = abs(
    expenses["amount"].sum()
) / 12

essential_spending = abs(
    expenses.loc[
        expenses["spending_category"].isin(essential_categories),
        "amount"
    ].sum()
)

average_monthly_essential_spending = (
    essential_spending / 12
)

all_spending_runway = (
    checking_cash / average_monthly_spending
)

essential_spending_runway = (
    checking_cash / average_monthly_essential_spending
)

runway = pd.Series(
    {
        "Normal Spending": all_spending_runway,
        "Essential Spending": essential_spending_runway
    }
)

plt.figure()

runway.plot(
    kind="bar"
)

for index, value in enumerate(runway): # Add exact runway values above each bar
    plt.text(
        index,
        value,
        f"{value:.2f}",
        ha="center",
        va="bottom"
    )

plt.title("Checking Cash Runway")
plt.xlabel("Spending Scenario")
plt.ylabel("Months of Spending Covered")
plt.xticks(rotation=0)
plt.tight_layout()

plt.savefig(
    chart_folder / "06_checking_cash_runway.png",
    dpi=300,
    bbox_inches="tight"
)
plt.close()

# CHART 7: Debt APR by lender
debt_apr = (
    debts[["lender", "apr"]]
    .copy()
    .sort_values("apr", ascending=False)
)

debt_apr["apr_percent"] = debt_apr["apr"] * 100

plt.figure()

debt_apr.plot(
    x="lender",
    y="apr_percent",
    kind="bar",
    legend=False
)

plt.title("Debt APR by Lender")
plt.xlabel("Lender")
plt.ylabel("APR (%)")
plt.xticks(rotation=45)
plt.tight_layout()

plt.savefig(
    chart_folder / "07_debt_apr_by_lender.png",
    dpi=300,
    bbox_inches="tight"
)
plt.close()

# Confirm that all chart files were generated successfully
print("\nAll visualization charts saved to dashboard/charts/")