import duckdb

print("Testing DuckDB...")
con = duckdb.connect(database='database.duckdb')
print("Success! DuckDB Connected.")
