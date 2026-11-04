with source_products as (
    select * from {{ source('bronze', 'olist_products_dataset') }}
),

source_translations as (
    select * from {{ source('bronze', 'product_category_name_translation') }}
),

renamed_and_cleaned as (
    select
        p.product_id,
        p.product_category_name as product_category_name_portuguese,
        -- Translated to English while keeping Portuguese name intact
        coalesce(t.product_category_name_english, p.product_category_name) as product_category_name_english,
        -- Standardized macro product group (e.g., furniture, appliances, electronics)
        {{ get_product_category_group("coalesce(t.product_category_name_english, p.product_category_name)") }} as product_category_group,
        cast(p.product_name_lenght as integer) as product_name_length,
        cast(p.product_description_lenght as integer) as product_description_length,
        cast(p.product_photos_qty as integer) as product_photos_qty,
        cast(p.product_weight_g as numeric(10, 2)) as product_weight_g,
        cast(p.product_length_cm as numeric(10, 2)) as product_length_cm,
        cast(p.product_height_cm as numeric(10, 2)) as product_height_cm,
        cast(p.product_width_cm as numeric(10, 2)) as product_width_cm,
        -- Deduplication on natural key
        row_number() over (
            partition by p.product_id
            order by p._dlt_load_id desc
        ) as row_num
    from source_products p
    left join source_translations t
        on p.product_category_name = t._product_category_name
)

select
    product_id,
    product_category_name_portuguese,
    product_category_name_english,
    product_category_group,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
from renamed_and_cleaned
where row_num = 1

