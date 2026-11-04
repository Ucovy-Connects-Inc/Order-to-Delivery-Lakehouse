with source as (
    select * from {{ source('bronze', 'olist_orders_dataset') }}
),

renamed_and_cleaned as (
    select
        order_id,
        customer_id,
        lower(trim(order_status)) as order_status,
        case 
            when lower(trim(order_status)) = 'canceled' then true 
            else false 
        end as is_canceled,
        -- Parsed to proper timestamp with NO timezone shift (Brazil local time)
        cast(order_purchase_timestamp as timestamp) as order_purchase_timestamp,
        cast(order_approved_at as timestamp) as order_approved_at,
        cast(order_delivered_carrier_date as timestamp) as order_delivered_carrier_date,
        cast(order_delivered_customer_date as timestamp) as order_delivered_customer_date,
        cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_date,
        -- Deduplication on natural key
        row_number() over (
            partition by order_id 
            order by order_purchase_timestamp desc nulls last, _dlt_load_id desc
        ) as row_num
    from source
)

select
    order_id,
    customer_id,
    order_status,
    is_canceled,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
from renamed_and_cleaned
where row_num = 1

