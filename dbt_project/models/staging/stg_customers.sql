with source as (
    select * from {{ source('bronze', 'olist_customers_dataset') }}
),

renamed_and_cleaned as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        initcap(trim(customer_city)) as customer_city,
        upper(trim(customer_state)) as customer_state,
        -- Deduplication on natural key
        row_number() over (
            partition by customer_id
            order by _dlt_load_id desc
        ) as row_num
    from source
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
from renamed_and_cleaned
where row_num = 1

