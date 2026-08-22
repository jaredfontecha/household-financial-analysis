# Financial Health Analysis
# Combines household income, spending, debt, and cash data to evaluate overall financial health,
# identify major risks, and build higher-level metrics and recommendations for the final project.

# Load cleaned transaction, debt, and account data for household financial health analysis
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql+psycopg2://Jared@localhost:5432/household_finance"
)

transactions = pd.read_sql(
    "SELECT * FROM clean.transactions WHERE duplicate_rank = 1;",
    engine
)

debts = pd.read_sql(
    "SELECT * FROM raw.debts;",
    engine
)

accounts = pd.read_sql(
    "SELECT * FROM raw.accounts;",
    engine
)

# Convert numeric fields and calculate core household totals
debts["balance"] = pd.to_numeric(debts["balance"])
debts["minimum_payment"] = pd.to_numeric(debts["minimum_payment"])
accounts["opening_balance"] = pd.to_numeric(accounts["opening_balance"])

annual_income = transactions.loc[
    transactions["transaction_type"] == "income",
    "amount"
].sum()

annual_spending = abs(
    transactions.loc[
        transactions["transaction_type"] == "expense",
        "amount"
    ].sum()
)

annual_net_cash_flow = annual_income - annual_spending

checking_cash = accounts.loc[
    accounts["account_type"] == "checking",
    "opening_balance"
].sum()

listed_debt = debts["balance"].sum()

# Adjust total known debt by adding credit card balances missing from the debt schedule
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

missing_credit_card_debt = credit_card_reconciliation.loc[
    credit_card_reconciliation["balance"].isna(),
    "account_balance"
].sum()

adjusted_total_debt = listed_debt + missing_credit_card_debt

# Calculate core household financial health ratios
average_monthly_income = annual_income / 12
average_monthly_spending = annual_spending / 12

cash_flow_margin = (
    annual_net_cash_flow
    / annual_income
    * 100
)

cash_to_debt_ratio = (
    checking_cash
    / adjusted_total_debt
    * 100
)

debt_to_income_ratio = (
    adjusted_total_debt
    / annual_income
    * 100
)

# Flag major household financial risks based on the calculated health metrics
financial_risks = []

if annual_net_cash_flow < 0:
    financial_risks.append("Negative annual cash flow")

if cash_to_debt_ratio < 25:
    financial_risks.append("Low cash coverage relative to debt")

if debt_to_income_ratio >= 40:
    financial_risks.append("High total debt relative to annual income")

# Create a simple financial health score based on major risk flags
financial_health_score = 100

financial_health_score -= len(financial_risks) * 20

if financial_health_score < 0:
    financial_health_score = 0

# Assign a simple financial health rating based on the custom score
if financial_health_score >= 80:
    financial_health_rating = "Strong"
elif financial_health_score >= 60:
    financial_health_rating = "Moderate"
else:
    financial_health_rating = "High Risk"

# Generate recommendation priorities based on the household's financial risks
recommendations = []

if annual_net_cash_flow < 0:
    recommendations.append(
        "Reduce discretionary spending to restore positive cash flow"
    )

if cash_to_debt_ratio < 25:
    recommendations.append(
        "Build a larger cash reserve relative to total debt"
    )

if debt_to_income_ratio >= 40:
    recommendations.append(
        "Prioritize debt reduction, especially high-APR balances"
    )

if financial_health_rating == "High Risk":
    recommendations.append(
        "Delay major new discretionary spending until financial stability improves"
    )

# Identify the household's largest discretionary spending category
discretionary_categories = [
    "Travel",
    "Shopping",
    "Dining",
    "Entertainment",
    "Fitness"
]

discretionary_spending = (
    transactions[
        (transactions["transaction_type"] == "expense")
        & (transactions["spending_category"].isin(discretionary_categories))
    ]
    .groupby("spending_category")["amount"]
    .sum()
    .abs()
    .reset_index(name="total_spent")
    .sort_values("total_spent", ascending=False)
)

largest_discretionary_category = discretionary_spending.iloc[0]

# Add a targeted recommendation using the largest discretionary spending category
largest_category_name = largest_discretionary_category["spending_category"]
largest_category_spend = largest_discretionary_category["total_spent"]

recommendations.append(
    f"Reduce {largest_category_name} spending, currently about ${largest_category_spend:,.2f} annually"
)

# Model how cutting the largest discretionary category would improve annual cash flow
scenario_cuts = [0.10, 0.20, 0.30]

scenario_results = []

for cut_rate in scenario_cuts:
    annual_savings = largest_category_spend * cut_rate
    new_net_cash_flow = annual_net_cash_flow + annual_savings

    scenario_results.append({
        "cut_percent": int(cut_rate * 100),
        "annual_savings": round(annual_savings, 2),
        "new_net_cash_flow": round(new_net_cash_flow, 2)
    })

scenario_analysis = pd.DataFrame(scenario_results)

# Calculate the cut required in the largest discretionary category to reach break-even cash flow
required_savings = abs(annual_net_cash_flow)

required_cut_percent = (
    required_savings
    / largest_category_spend
    * 100
)

# Model combined spending cuts across all discretionary categories
total_discretionary_spending = discretionary_spending["total_spent"].sum()

combined_cut_rates = [0.10, 0.20, 0.30]

combined_scenario_results = []

for cut_rate in combined_cut_rates:
    annual_savings = total_discretionary_spending * cut_rate
    new_net_cash_flow = annual_net_cash_flow + annual_savings

    combined_scenario_results.append({
        "cut_percent": int(cut_rate * 100),
        "annual_savings": round(annual_savings, 2),
        "new_net_cash_flow": round(new_net_cash_flow, 2)
    })

combined_scenario_analysis = pd.DataFrame(combined_scenario_results)

# Calculate the discretionary spending cut required to reach break-even cash flow
required_discretionary_cut_percent = (
    abs(annual_net_cash_flow)
    / total_discretionary_spending
    * 100
)

# Model combined discretionary spending cuts and income increases
# Test a wider range of discretionary spending cuts
spending_cut_rates = [
    0.10,
    0.20,
    0.30,
    0.40,
    0.50,
    0.60,
    0.70,
    0.80
]
income_increase_rates = [0.05, 0.10, 0.20]

combined_plan_results = []

for spending_cut in spending_cut_rates:
    for income_increase in income_increase_rates:
        annual_savings = total_discretionary_spending * spending_cut
        additional_income = annual_income * income_increase

        new_net_cash_flow = (
            annual_net_cash_flow
            + annual_savings
            + additional_income
        )

        combined_plan_results.append({
            "spending_cut_percent": int(spending_cut * 100),
            "income_increase_percent": int(income_increase * 100),
            "annual_savings": round(annual_savings, 2),
            "additional_income": round(additional_income, 2),
            "new_net_cash_flow": round(new_net_cash_flow, 2)
        })

combined_plan_analysis = pd.DataFrame(combined_plan_results)

# Calculate the income increase required to break even at each spending-cut level
break_even_scenarios = []

for spending_cut in spending_cut_rates:
    annual_savings = total_discretionary_spending * spending_cut

    remaining_deficit = abs(
        annual_net_cash_flow + annual_savings
    )

    required_income_increase_percent = (
        remaining_deficit
        / annual_income
        * 100
    )

    break_even_scenarios.append({
        "spending_cut_percent": int(spending_cut * 100),
        "annual_savings": round(annual_savings, 2),
        "required_income_increase_percent": round(
            required_income_increase_percent,
            2
        )
    })

break_even_plan = pd.DataFrame(break_even_scenarios)

# Compare essential and discretionary spending as shares of total annual spending
essential_categories = [
    "Housing",
    "Utilities",
    "Groceries",
    "Transportation"
]

essential_spending = abs(
    transactions.loc[
        (transactions["transaction_type"] == "expense")
        & (transactions["spending_category"].isin(essential_categories)),
        "amount"
    ].sum()
)

discretionary_spending_total = discretionary_spending["total_spent"].sum()

essential_spending_share = (
    essential_spending / annual_spending * 100
)

discretionary_spending_share = (
    discretionary_spending_total / annual_spending * 100
)

# Calculate the household's minimum spending floor if all discretionary spending were eliminated
minimum_annual_spending = essential_spending

minimum_net_cash_flow = (
    annual_income
    - minimum_annual_spending
)

minimum_cash_flow_margin = (
    minimum_net_cash_flow
    / annual_income
    * 100
)

# Final outputs for household financial health analysis
print("\n=== HOUSEHOLD FINANCIAL HEALTH SUMMARY ===")

print("\nCore financial health metrics:")
print("Annual income:", round(annual_income, 2))
print("Annual spending:", round(annual_spending, 2))
print("Annual net cash flow:", round(annual_net_cash_flow, 2))
print("Cash flow margin:", round(cash_flow_margin, 2), "%")
print("Cash-to-debt ratio:", round(cash_to_debt_ratio, 2), "%")
print("Debt-to-income ratio:", round(debt_to_income_ratio, 2), "%")

print("\nFinancial risk flags:")
for risk in financial_risks:
    print("-", risk)

print("\nCustom financial health assessment:")
print("Score:", financial_health_score, "/ 100")
print("Rating:", financial_health_rating)

print("\nRecommendation priorities:")
for recommendation in recommendations:
    print("-", recommendation)

print("\nEssential vs discretionary spending:")
print("Essential annual spending:", round(essential_spending, 2))
print("Essential share:", round(essential_spending_share, 2), "%")
print("Discretionary annual spending:", round(discretionary_spending_total, 2))
print("Discretionary share:", round(discretionary_spending_share, 2), "%")

print("\nBreak-even plan by discretionary spending-cut level:")
print(break_even_plan)

print("\nMinimum spending floor:")
print("Minimum annual spending:", round(minimum_annual_spending, 2))
print("Net cash flow at minimum spending:", round(minimum_net_cash_flow, 2))
print("Cash flow margin at minimum spending:", round(minimum_cash_flow_margin, 2), "%")