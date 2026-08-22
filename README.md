# Household Financial Analysis

A full-cycle household financial analysis project using PostgreSQL, SQL, Python, pandas, Matplotlib, and Excel to transform raw financial data into actionable insights.

## Project Overview

This project analyzes a household's 2025 transactions, accounts, and debt to evaluate spending behavior, liquidity, debt burden, and overall financial health. The workflow covers data cleaning and classification in SQL, financial analysis in Python, data visualization with Matplotlib, and final reporting through an Excel dashboard and PowerPoint presentation.

## Key Findings

- Annual spending totaled **$372,066.27**, compared with annual income of **$174,923.04**.
- The household generated an annual net cash flow of **-$197,143.23**.
- Travel was the largest spending category at **$153,896.94**, representing **41.36%** of total spending.
- March and October were the only months at least 10% above average monthly spending.
- Adjusted total known debt was **$85,550**, with **$19,000** in checking cash.
- Credit cards represented **13.86%** of listed debt principal but **41.05%** of estimated annual interest cost.
- The custom financial health score was **40/100 (High Risk)**.

## Tools & Technologies

- **PostgreSQL** — database storage and querying
- **SQL** — data cleaning, transaction classification, merchant standardization, and financial analysis
- **Python** — analysis workflow and automation
- **pandas** — data manipulation and aggregation
- **Matplotlib** — financial visualizations
- **Excel** — dashboard creation and presentation of key metrics
- **Git & GitHub** — version control and project documentation

## Project Workflow

1. Imported raw transaction, account, and debt data into PostgreSQL.
2. Cleaned duplicate transactions and standardized merchant names in SQL.
3. Classified transactions and categorized expenses.
4. Analyzed spending patterns, debt burden, liquidity, and financial health with Python and pandas.
5. Created visualizations with Matplotlib.
6. Built an Excel dashboard to summarize key metrics and findings.
7. Created a PowerPoint presentation with the final analysis and recommendations.

## Project Structure

- `data/` — raw and processed financial datasets
- `sql/` — PostgreSQL scripts for data validation, cleaning, classification, categorization, and financial analysis
- `python/` — Python scripts for spending, debt, financial health, and visualization analysis
- `dashboard/charts/` — generated financial charts
- `excel/` — Excel dashboard workbook
- `presentation/` — final PowerPoint presentation

## How to Run the Project

1. Load the raw CSV files into the PostgreSQL `household_finance` database.
2. Run the SQL scripts in numerical order from `sql/01_create_raw_tables.sql` through `sql/09_accounts_and_debt_analysis.sql`.
3. Run the Python scripts in numerical order:

   `python3 python/01_load_clean_data.py`

   `python3 python/02_spending_analysis.py`

   `python3 python/03_debt_analysis.py`

   `python3 python/04_financial_health_analysis.py`

   `python3 python/05_visualizations.py`

4. Review the generated charts in `dashboard/charts/`.
5. Open the Excel dashboard in `excel/household_financial_dashboard.xlsx`.
6. Review the final presentation in `presentation/household_financial_analysis_presentation.pptx`.

## Skills Demonstrated

- Relational database design and PostgreSQL querying
- SQL data cleaning, validation, classification, and aggregation
- Python and pandas for financial analysis
- Data reconciliation and identification of missing/inconsistent records
- Financial ratio and cash-flow analysis
- Scenario and break-even analysis
- Data visualization with Matplotlib
- Excel dashboard development
- Presentation of financial insights to a non-technical audience
- Git and GitHub version control