import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql+psycopg2://Jared@localhost:5432/household_finance"
)

df = pd.read_sql(
    "SELECT * FROM clean.transactions WHERE duplicate_rank = 1;",
    engine
)

expenses = df[df["transaction_type"] == "expense"].copy()

# Calculate total spending by each category
category_spending = (
    expenses.groupby("spending_category")["amount"]
    .sum()
    .abs()
    .sort_values(ascending=False)
)

# Create df with total spending and transaction count
# Don't forget to index it so "categories" aren't numbering rows
# Also added avg transaction size and percent of total spending to df
category_summary = (
    expenses.groupby("spending_category")
    .agg(
        total_spent=("amount", lambda x: abs(x.sum())),
        transaction_count=("transaction_id", "count"),
        average_transaction=("amount", lambda x: x.abs().mean())
    )
    .sort_values("total_spent", ascending=False)
)

category_summary = category_summary.reset_index()

category_summary["percent_of_total"] = (
    category_summary["total_spent"]
    / category_summary["total_spent"].sum()
    * 100
)

# Don't forget to round
category_summary["average_transaction"] = (
    category_summary["average_transaction"].round(2)
)

category_summary["percent_of_total"] = (
    category_summary["percent_of_total"].round(2)
)

#Create df for monthly spending trends
expenses["transaction_date"] = pd.to_datetime(expenses["transaction_date"])
expenses["month"] = expenses["transaction_date"].dt.to_period("M").astype(str)

monthly_spending = (
    expenses.groupby("month")["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
)

#Compare each month to normal monthly spending habits
average_monthly_spending = monthly_spending["total_spent"].mean()

monthly_spending["vs_average"] = (
    monthly_spending["total_spent"] - average_monthly_spending
)

monthly_spending["percent_vs_average"] = (
    monthly_spending["vs_average"]
    / average_monthly_spending
    * 100
).round(2)

#Flag unsually high-spending months
monthly_spending["spending_flag"] = monthly_spending["percent_vs_average"].apply(
    lambda x: "High" if x >= 10 else "Normal"
)

#Create new df to see which categories caused the highest spending months
high_spending_months = monthly_spending.loc[
    monthly_spending["spending_flag"] == "High",
    "month"
].tolist()
# adding this allows other datasets to be used (no hard code)

high_month_category_spending = (
    expenses[expenses["month"].isin(high_spending_months)]
    .groupby(["month", "spending_category"])["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
    .sort_values(["month", "total_spent"], ascending=[True, False])
)

##Create new df to see highest spending categories for all months
monthly_category_spending = (
    expenses.groupby(["month", "spending_category"])["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
)

top_category_by_month = (
    monthly_category_spending
    .sort_values(["month", "total_spent"], ascending=[True, False])
    .groupby("month")
    .head(1)
    .reset_index(drop=True)
)

#Merge to see what percentage of total spending is travel
travel_monthly = (
    monthly_category_spending[
        monthly_category_spending["spending_category"] == "Travel"
    ]
    .merge(
        monthly_spending,
        on="month",
        how="left"
    )
)

travel_monthly = travel_monthly.rename(
    columns={
        "total_spent_x": "travel_spent",
        "total_spent_y": "monthly_total_spent"
    }
)

travel_monthly["travel_percent_of_month"] = (
    travel_monthly["travel_spent"]
    / travel_monthly["monthly_total_spent"]
    * 100
).round(2)

#Create df to see how spending is ditributed amongst travel merchants
travel_expenses = expenses[
    expenses["spending_category"] == "Travel"
]

travel_merchant_summary = (
    travel_expenses.groupby("merchant_standardized")["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
    .sort_values("total_spent", ascending=False)
)

#Convert above df to percentage table 
travel_merchant_summary["percent_of_travel"] = (
    travel_merchant_summary["total_spent"]
    / travel_merchant_summary["total_spent"].sum()
    * 100
).round(2)

#Create df to see which travel merchants dominated which months
travel_by_month_merchant = (
    travel_expenses.groupby(["month", "merchant_standardized"])["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
    .sort_values(["month", "total_spent"], ascending=[True, False])
)

travel_month_totals = (
    travel_by_month_merchant.groupby("month")["total_spent"]
    .sum()
    .reset_index(name="monthly_travel_spent")
)

travel_by_month_merchant = travel_by_month_merchant.merge(
    travel_month_totals,
    on="month",
    how="left"
)

travel_by_month_merchant["percent_of_monthly_travel"] = (
    travel_by_month_merchant["total_spent"]
    / travel_by_month_merchant["monthly_travel_spent"]
    * 100
).round(2)

top_travel_merchant_by_month = (
    travel_by_month_merchant
    .sort_values(
        ["month", "percent_of_monthly_travel"],
        ascending=[True, False]
    )
    .groupby("month")
    .head(1)
    .reset_index(drop=True)
)

# Find the top spending category driving each high-spending month
top_driver_by_high_month = (
    high_month_category_spending
    .groupby("month")
    .head(1)
    .reset_index(drop=True)
)

# Find the top merchant driving each high-spending month
high_month_merchant_spending = (
    expenses[expenses["month"].isin(high_spending_months)]
    .groupby(["month", "merchant_standardized"])["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
    .sort_values(["month", "total_spent"], ascending=[True, False])
)

top_merchant_by_high_month = (
    high_month_merchant_spending
    .groupby("month")
    .head(1)
    .reset_index(drop=True)
)

# Convert above chart to percentage of each month
top_merchant_by_high_month = top_merchant_by_high_month.merge(
    monthly_spending[["month", "total_spent"]],
    on="month",
    how="left"
)

top_merchant_by_high_month["percent_of_month"] = (
    top_merchant_by_high_month["total_spent_x"]
    / top_merchant_by_high_month["total_spent_y"]
    * 100
).round(2)

# Rename merged spending columns for easier reading
top_merchant_by_high_month = top_merchant_by_high_month.rename(
    columns={
        "total_spent_x": "merchant_spent",
        "total_spent_y": "monthly_total_spent"
    }
)

#Is March travel high compared to a normal travel month?
# Calculate each category's normal monthly spending level
category_monthly_average = (
    monthly_category_spending.groupby("spending_category")["total_spent"]
    .mean()
    .reset_index(name="average_monthly_category_spent")
)

category_anomalies = monthly_category_spending.merge(
    category_monthly_average,
    on="spending_category",
    how="left"
)

category_anomalies["percent_vs_category_average"] = (
    (
        category_anomalies["total_spent"]
        - category_anomalies["average_monthly_category_spent"]
    )
    / category_anomalies["average_monthly_category_spent"]
    * 100
).round(2)

# Flag category-month combinations that are 25% or more above their normal level
category_anomalies["anomaly_flag"] = category_anomalies[
    "percent_vs_category_average"
].apply(
    lambda x: "High" if x >= 25 else "Normal"
)

high_category_anomalies = (
    category_anomalies[
        category_anomalies["anomaly_flag"] == "High"
    ]
    .sort_values("percent_vs_category_average", ascending=False)
    .reset_index(drop=True)
)


# Find the single biggest spending anomaly for each category
biggest_anomaly_by_category = (
    high_category_anomalies
    .sort_values(
        ["spending_category", "percent_vs_category_average"],
        ascending=[True, False]
    )
    .groupby("spending_category")
    .head(1)
    .reset_index(drop=True)
)

# Final outputs for the spending analysis
print("\n=== SPENDING ANALYSIS SUMMARY ===")

# Where is the money going?
print("\nCategory summary:")
print(category_summary)

# Which months are unsually high?
print("\nMonthly spending flags:")
print(monthly_spending)

# What caused those high months
print("\nTop category driver for each high-spending month:")
print(top_driver_by_high_month)

# Which merchant drove them?
print("\nTop merchant share of each high-spending month:")
print(top_merchant_by_high_month)

# Which categories had unusual spikes?
print("\nBiggest anomaly by category:")
print(biggest_anomaly_by_category)