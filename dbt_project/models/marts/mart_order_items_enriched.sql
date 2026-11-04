with items as (
    select * from {{ ref('fact_order_items') }}
),

products as (
    select * from {{ ref('dim_product') }}
),

customers as (
    select * from {{ ref('dim_customer') }}
),

sellers as (
    select * from {{ ref('dim_seller') }}
)

select
    items.order_id,
    items.order_item_id,
    items.product_id,
    items.seller_id,
    items.customer_id,
    items.order_status,
    items.order_purchase_timestamp,
    items.order_purchase_date,
    items.shipping_limit_date,

    -- Item Financials
    items.price,
    items.freight_value,
    items.total_item_value,
    case 
        when items.price > 0 then round((items.freight_value / items.price) * 100.0, 2)
        else 0.0 
    end as freight_ratio_pct,

    -- Product Attributes
    coalesce(products.product_category_name_english, 'unknown') as product_category_name_english,
    coalesce(products.product_category_group, 'other_or_uncategorized') as product_category_group,
    products.product_category_name_portuguese,
    products.product_weight_g,

    -- Geography
    customers.customer_state,
    customers.customer_city,
    sellers.seller_state,
    sellers.seller_city,
    case when customers.customer_state = sellers.seller_state then true else false end as is_same_state_delivery

from items
left join products
    on items.product_id = products.product_id
left join customers
    on items.customer_id = customers.customer_id
left join sellers
    on items.seller_id = sellers.seller_id

