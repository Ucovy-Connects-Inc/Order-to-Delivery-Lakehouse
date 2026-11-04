with source as (
    select * from {{ source('bronze', 'olist_sellers_dataset') }}
),

renamed_and_cleaned as (
    select
        seller_id,
        seller_zip_code_prefix,
        initcap(trim(seller_city)) as seller_city,
        upper(trim(seller_state)) as seller_state,
        -- Deduplication on natural key
        row_number() over (
            partition by seller_id
            order by _dlt_load_id desc
        ) as row_num
    from source
)

select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
from renamed_and_cleaned
where row_num = 1

