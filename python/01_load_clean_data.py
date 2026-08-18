import pandas as pd
from sqlalchemy import create_engine

# Connect Python to the PostgreSQL household_finance database
engine = create_engine(
    "postgresql+psycopg2://Jared@localhost:5432/household_finance"
)

# Load the cleaned transactions table into a pandas DataFrame
df = pd.read_sql(
    "SELECT * FROM clean.transactions WHERE duplicate_rank = 1;",
    engine
)

# Show the first 5 rows
print(df.head())