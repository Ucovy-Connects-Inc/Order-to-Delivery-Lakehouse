import os
import csv
import sys
import time
from pathlib import Path
from dotenv import load_dotenv
import dlt
from dlt.destinations import postgres
import psycopg2

load_dotenv()

RAW_DIR = Path("data/raw")
EXPECTED_FILES = [
    "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_customers_dataset.csv",
    "olist_sellers_dataset.csv",
    "olist_products_dataset.csv",
    "olist_geolocation_dataset.csv",
    "product_category_name_translation.csv",
]

def get_connection_params():
    user = os.getenv("POSTGRES_USER", "postgres")
    password = os.getenv("POSTGRES_PASSWORD", "postgres")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "lakehouse")
    return {
        "user": user,
        "password": password,
        "host": host,
        "port": port,
        "database": db,
        "url": f"postgresql://{user}:{password}@{host}:{port}/{db}",
    }

def make_csv_generator(file_path: Path, batch_size=25000):
    def _generator():
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            reader = csv.DictReader(f)
            batch = []
            for row in reader:
                batch.append({k: (v if v != "" else None) for k, v in row.items()})
                if len(batch) >= batch_size:
                    yield batch
                    batch = []
            if batch:
                yield batch
    return _generator

def count_csv_rows(file_path: Path) -> int:
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        reader = csv.reader(f)
        try:
            next(reader)  # skip header
        except StopIteration:
            return 0
        return sum(1 for _ in reader)

def main():
    # 1. Check all 9 files exist in data/raw/
    missing = [f for f in EXPECTED_FILES if not (RAW_DIR / f).exists()]
    if missing:
        print(f"Error: Missing {len(missing)} CSV file(s) in {RAW_DIR}:", file=sys.stderr)
        for m in missing:
            print(f"  - {m}", file=sys.stderr)
        print("Please ensure Step 1 is complete before running the bronze loader.", file=sys.stderr)
        sys.exit(1)

    conn_params = get_connection_params()
    dest = postgres(conn_params["url"])
    pipeline = dlt.pipeline(
        pipeline_name="olist_bronze_pipeline",
        destination=dest,
        dataset_name="bronze",
    )

    print("=================================================================")
    print("           OLIST LAKEHOUSE: BRONZE INGESTION (dlt)               ")
    print("=================================================================")
    print(f"Destination: Postgres ({conn_params['host']}:{conn_params['port']}/{conn_params['database']})")
    print(f"Schema: bronze\n")

    # 2. Build dlt resources for all 9 CSV files
    resources = []
    for filename in EXPECTED_FILES:
        file_path = RAW_DIR / filename
        table_name = file_path.stem
        gen = make_csv_generator(file_path)
        r = dlt.resource(
            gen,
            name=table_name,
            table_name=table_name,
            write_disposition="replace",
        )
        resources.append(r)

    print(f"Loading {len(resources)} resources into Postgres bronze schema...")
    t0 = time.time()
    info = pipeline.run(resources)
    load_time = time.time() - t0
    print(f"Ingestion completed in {load_time:.2f}s.\n")
    print(info)
    print()

    # 3. Create schema alias views without `_dataset` suffix
    print("Creating alias views (e.g. bronze.olist_orders -> bronze.olist_orders_dataset)...")
    try:
        conn = psycopg2.connect(
            dbname=conn_params["database"],
            user=conn_params["user"],
            password=conn_params["password"],
            host=conn_params["host"],
            port=conn_params["port"],
        )
        conn.autocommit = True
        with conn.cursor() as cur:
            for filename in EXPECTED_FILES:
                stem = Path(filename).stem
                if stem.endswith("_dataset"):
                    short_name = stem[:-8]
                    cur.execute(f'CREATE OR REPLACE VIEW bronze."{short_name}" AS SELECT * FROM bronze."{stem}";')
        print("Alias views created successfully.\n")
    except Exception as e:
        print(f"Warning: Could not create alias views: {e}\n")
    finally:
        if 'conn' in locals() and conn:
            conn.close()

    # 4. Independent Row Count Verification
    print("=================================================================")
    print("            INDEPENDENT ROW COUNT VERIFICATION                   ")
    print("=================================================================")
    print(f"{'Table Name':<38} | {'CSV Rows':>10} | {'Postgres':>10} | {'Status':<6}")
    print("-" * 72)

    all_matched = True
    try:
        conn = psycopg2.connect(
            dbname=conn_params["database"],
            user=conn_params["user"],
            password=conn_params["password"],
            host=conn_params["host"],
            port=conn_params["port"],
        )
        with conn.cursor() as cur:
            for filename in EXPECTED_FILES:
                file_path = RAW_DIR / filename
                table_name = file_path.stem
                csv_count = count_csv_rows(file_path)
                
                cur.execute(f'SELECT count(*) FROM bronze."{table_name}";')
                pg_count = cur.fetchone()[0]

                match = (csv_count == pg_count)
                status = "PASS" if match else "FAIL"
                if not match:
                    all_matched = False

                print(f"{table_name:<38} | {csv_count:>10,d} | {pg_count:>10,d} | {status:<6}")
    finally:
        if 'conn' in locals() and conn:
            conn.close()

    print("-" * 72)
    if all_matched:
        print("RESULT: SUCCESS - All 9 bronze tables exist and row counts match 100%!")
    else:
        print("RESULT: MISMATCH DETECTED - One or more table row counts differ from CSV.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
