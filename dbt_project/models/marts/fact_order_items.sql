with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
)

select
    items.order_id,
    items.order_item_id,
    items.product_id,
    items.seller_id,
    orders.customer_id,
    orders.order_status,
    orders.order_purchase_timestamp,
    cast(orders.order_purchase_timestamp as date) as order_purchase_date,
    items.shipping_limit_date,
    items.price,
    items.freight_value,
    (items.price + items.freight_value) as total_item_value
from order_items items
inner join orders
    on items.order_id = orders.order_id

