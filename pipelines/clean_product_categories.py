"""
Product Category Grouping & Data Cleaning Pipeline
=================================================
This module maps Olist's 74 granular product categories into 17 standardized
macro product groups (e.g. furniture_decor -> furniture, office_furniture -> furniture).

Usage:
    - In Python:
        from pipelines.clean_product_categories import get_category_group, CATEGORY_MAPPING
        macro_group = get_category_group("furniture_living_room")  # returns "furniture"
    - CLI validation against Lakehouse PostgreSQL:
        python pipelines/clean_product_categories.py
"""

import os
import sys
from typing import Dict, List, Optional
import psycopg2
from dotenv import load_dotenv

# Master dictionary: Macro Product Group -> List of Granular Categories
CATEGORY_MAPPING: Dict[str, List[str]] = {
    "furniture": [
        "furniture_decor",
        "office_furniture",
        "furniture_living_room",
        "kitchen_dining_laundry_garden_furniture",
        "furniture_bedroom",
        "furniture_mattress_and_upholstery",
    ],
    "home_and_garden": [
        "bed_bath_table",
        "housewares",
        "garden_tools",
        "home_confort",
        "home_comfort_2",
        "flowers",
        "la_cuisine",
    ],
    "computers_and_electronics": [
        "computers_accessories",
        "telephony",
        "electronics",
        "fixed_telephony",
        "audio",
        "computers",
        "tablets_printing_image",
        "pc_gamer",
        "cine_photo",
    ],
    "appliances": [
        "home_appliances",
        "small_appliances",
        "air_conditioning",
        "home_appliances_2",
        "small_appliances_home_oven_and_coffee",
        "portateis_cozinha_e_preparadores_de_alimentos",
    ],
    "health_and_beauty": [
        "health_beauty",
        "perfumery",
        "diapers_and_hygiene",
    ],
    "fashion_and_apparel": [
        "fashion_bags_accessories",
        "luggage_accessories",
        "fashion_shoes",
        "fashion_male_clothing",
        "fashion_underwear_beach",
        "fashio_female_clothing",
        "fashion_sport",
        "fashion_childrens_clothes",
        "watches_gifts",
    ],
    "sports_and_leisure": [
        "sports_leisure",
    ],
    "baby_and_toys": [
        "toys",
        "baby",
    ],
    "auto_and_parts": [
        "auto",
    ],
    "tools_and_construction": [
        "construction_tools_construction",
        "home_construction",
        "signaling_and_security",
        "construction_tools_safety",
        "costruction_tools_garden",
        "construction_tools_lights",
        "costruction_tools_tools",
    ],
    "stationery_and_office": [
        "stationery",
    ],
    "arts_hobbies_and_party": [
        "consoles_games",
        "musical_instruments",
        "art",
        "arts_and_craftmanship",
        "party_supplies",
        "christmas_supplies",
    ],
    "pet_shop": [
        "pet_shop",
    ],
    "food_and_beverages": [
        "food_drink",
        "food",
        "drinks",
    ],
    "books_and_media": [
        "books_general_interest",
        "books_technical",
        "books_imported",
        "dvds_blu_ray",
        "music",
        "cds_dvds_musicals",
    ],
    "industry_and_business": [
        "agro_industry_and_commerce",
        "industry_commerce_and_business",
        "market_place",
        "security_and_services",
    ],
}

# Inverted mapping: Granular Category -> Macro Group
INVERTED_MAPPING: Dict[str, str] = {
    granular: macro
    for macro, granular_list in CATEGORY_MAPPING.items()
    for granular in granular_list
}


def get_category_group(category_name: Optional[str]) -> str:
    """
    Returns the standardized macro product group for a given granular category name.
    If category is None or unmapped, returns 'other_or_uncategorized'.
    """
    if not category_name:
        return "other_or_uncategorized"
    clean_key = category_name.strip().lower()
    return INVERTED_MAPPING.get(clean_key, "other_or_uncategorized")


def validate_against_database():
    """Validates the mapping against products and order items in PostgreSQL."""
    load_dotenv()
    db_name = os.getenv("POSTGRES_DB", "lakehouse")
    user = os.getenv("POSTGRES_USER", "postgres")
    password = os.getenv("POSTGRES_PASSWORD", "postgres")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")

    print(f"Connecting to PostgreSQL ({user}@{host}:{port}/{db_name})...")
    conn = psycopg2.connect(
        dbname=db_name, user=user, password=password, host=host, port=port
    )
    cur = conn.cursor()

    cur.execute("""
        SELECT COALESCE(product_category_name_english, 'uncategorized') as cat, COUNT(*) as cnt
        FROM gold.dim_product
        GROUP BY 1;
    """)
    rows = cur.fetchall()

    group_counts: Dict[str, int] = {}
    for cat, cnt in rows:
        grp = get_category_group(cat)
        group_counts[grp] = group_counts.get(grp, 0) + cnt

    total_products = sum(group_counts.values())
    print("\n" + "=" * 65)
    print("PRODUCT CATALOG DISTRIBUTION BY MACRO CATEGORY")
    print("=" * 65)
    for grp, cnt in sorted(group_counts.items(), key=lambda x: x[1], reverse=True):
        pct = (cnt / total_products) * 100
        print(f"  {grp:28}: {cnt:>6} products ({pct:5.2f}%)")
    print("-" * 65)
    print(f"  {'TOTAL':28}: {total_products:>6} products (100.00%)")
    print("=" * 65 + "\n")

    cur.close()
    conn.close()


if __name__ == "__main__":
    validate_against_database()

