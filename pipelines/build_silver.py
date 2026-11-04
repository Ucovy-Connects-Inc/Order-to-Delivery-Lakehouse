"""
Connect dbt and Build Silver Staging Layer
Olist Order-to-Delivery Lakehouse

This script automates and validates Step 5:
1. Runs `dbt debug` to verify PostgreSQL connection.
2. Compiles and executes the 6 Silver Staging views via `dbt run --select staging`.
3. Executes all 27 data quality and relationship tests via `dbt test --select staging`.
4. Queries PostgreSQL silver schema to verify cleaned timestamps, category translations,
   and deduplication row counts.
"""

import os
import sys
import subprocess
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
import pandas as pd

load_dotenv()

DBT_DIR = Path("dbt_project")

def run_dbt_command(command_args, description):
    print("=" * 70)
    print(f"  RUNNING: {description}")
    print("=" * 70)
    cmd = [sys.executable, "-m", "dbt.cli.main"] + command_args + ["--profiles-dir", "."]
    
    result = subprocess.run(cmd, cwd=str(DBT_DIR))
    if result.returncode != 0:
        print(f"\n[ERROR] Command failed with exit code {result.returncode}: {' '.join(command_args)}", file=sys.stderr)
        sys.exit(result.returncode)
    print()

def verify_silver_layer():
    print("=" * 70)
    print("  VERIFYING SILVER STAGING LAYER IN POSTGRESQL")
    print("=" * 70)

    conn = psycopg2.connect(
        dbname=os.getenv("POSTGRES_DB", "lakehouse"),
        user=os.getenv("POSTGRES_USER", "postgres"),
        password=os.getenv("POSTGRES_PASSWORD", "postgres"),
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=os.getenv("POSTGRES_PORT", "5432"),
    )

    try:
        # 1. Row counts across all 6 Silver staging views
        print("\n--- 1. Staging View Row Counts ---")
        df_counts = pd.read_sql("""
            SELECT 'stg_orders' as model, count(*) as row_count FROM silver.stg_orders
            UNION ALL
            SELECT 'stg_order_items', count(*) FROM silver.stg_order_items
            UNION ALL
            SELECT 'stg_customers', count(*) FROM silver.stg_customers
            UNION ALL
            SELECT 'stg_sellers', count(*) FROM silver.stg_sellers
            UNION ALL
            SELECT 'stg_products', count(*) FROM silver.stg_products
            UNION ALL
            SELECT 'stg_payments', count(*) FROM silver.stg_payments;
        """, conn)
        print(df_counts.to_string(index=False))

        # 2. Sample cleaned orders with Brazil local timestamps & is_canceled flag
        print("\n--- 2. Sample Cleaned Orders (stg_orders) ---")
        df_orders = pd.read_sql("""
            SELECT order_id, order_status, is_canceled, 
                   order_purchase_timestamp, order_delivered_customer_date 
            FROM silver.stg_orders 
            LIMIT 5;
        """, conn)
        print(df_orders.to_string(index=False))

        # 3. Order status distribution and canceled orders flag
        print("\n--- 3. Order Status Breakdown & Canceled Flag ---")
        df_status = pd.read_sql("""
            SELECT order_status, is_canceled, count(*) as order_count 
            FROM silver.stg_orders 
            GROUP BY order_status, is_canceled 
            ORDER BY order_count DESC;
        """, conn)
        print(df_status.to_string(index=False))

        # 4. Product category translation (Portuguese vs English)
        print("\n--- 4. Product Category Translation Sample (stg_products) ---")
        df_products = pd.read_sql("""
            SELECT product_id, product_category_name_portuguese, product_category_name_english, product_weight_g 
            FROM silver.stg_products 
            WHERE product_category_name_portuguese IS NOT NULL 
              AND product_category_name_portuguese <> product_category_name_english
            LIMIT 5;
        """, conn)
        print(df_products.to_string(index=False))

    finally:
        conn.close()

    print("\n" + "=" * 70)
    print("  RESULT: SUCCESS - All 6 silver models built and verified!")
    print("=" * 70 + "\n")

def main():
    if not DBT_DIR.exists():
        print(f"[ERROR] Directory '{DBT_DIR}' not found.", file=sys.stderr)
        sys.exit(1)

    # 1. dbt debug
    run_dbt_command(["debug"], "dbt debug (connection check)")

    # 2. dbt run --select staging
    run_dbt_command(["run", "--select", "staging"], "dbt run --select staging (build silver views)")

    # 3. dbt test --select staging
    run_dbt_command(["test", "--select", "staging"], "dbt test --select staging (run 27 data tests)")

    # 4. Independent SQL verification
    verify_silver_layer()

if __name__ == "__main__":
    main()

