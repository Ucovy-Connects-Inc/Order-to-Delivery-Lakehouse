with source as (
    select * from {{ source('bronze', 'olist_order_items_dataset') }}
),

renamed_and_cleaned as (
    select
        order_id,
        cast(order_item_id as integer) as order_item_id,
        product_id,
        seller_id,
        cast(shipping_limit_date as timestamp) as shipping_limit_date,
        cast(price as numeric(10, 2)) as price,
        cast(freight_value as numeric(10, 2)) as freight_value,
        -- Deduplication on natural composite key (order_id + order_item_id)
        row_number() over (
            partition by order_id, order_item_id
            order by _dlt_load_id desc
        ) as row_num
    from source
)

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
from renamed_and_cleaned
where row_num = 1

