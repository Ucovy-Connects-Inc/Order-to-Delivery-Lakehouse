import sys
import argparse
from pathlib import Path

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

TARGET_DIR = Path("data/raw")
DATASET = "olistbr/brazilian-ecommerce"

def check_files_exist():
    if not TARGET_DIR.exists():
        return False
    present = {f.name for f in TARGET_DIR.glob("*.csv")}
    return all(f in present for f in EXPECTED_FILES)

def download(force=False):
    TARGET_DIR.mkdir(parents=True, exist_ok=True)
    
    if not force and check_files_exist():
        print("All 9 Olist CSV files are already present in data/raw/. Skipping download.")
        print("Use --force to re-download if needed.")
        return

    print(f"Downloading dataset '{DATASET}' to '{TARGET_DIR}'...")
    try:
        from kaggle.api.kaggle_api_extended import KaggleApi
        api = KaggleApi()
        api.authenticate()
        api.dataset_download_files(DATASET, path=str(TARGET_DIR), unzip=True)
        print("Download and extraction complete.")
    except Exception as e:
        print(f"Error downloading dataset: {e}", file=sys.stderr)
        print("Please check your Kaggle credentials (~/.kaggle/kaggle.json or KAGGLE_USERNAME / KAGGLE_KEY).", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Download Olist dataset from Kaggle")
    parser.add_argument("--force", action="store_true", help="Force re-download even if files exist")
    args = parser.parse_args()

    download(force=args.force)

if __name__ == "__main__":
    main()

