with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

order_items_agg as (
    select
        order_id,
        count(*) as total_items,
        sum(price) as total_order_price,
        sum(freight_value) as total_freight_value
    from {{ ref('stg_order_items') }}
    group by order_id
),

final as (
    select
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_status,
        o.is_canceled,
        -- Timestamps
        o.order_purchase_timestamp,
        cast(o.order_purchase_timestamp as date) as order_purchase_date,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        -- Delivered flag matching staging delivered status exactly
        case 
            when o.order_status = 'delivered' then true 
            else false 
        end as is_delivered,

        -- On-time delivery flag (delivered orders with valid delivery date <= estimated delivery date)
        case 
            when o.order_status = 'delivered' and o.order_delivered_customer_date is not null then
                case 
                    when o.order_delivered_customer_date <= o.order_estimated_delivery_date then true 
                    else false 
                end
            when o.order_status = 'delivered' then false
            else null
        end as is_on_time,

        -- Delivery durations in days (delivered orders with valid timestamps)
        case 
            when o.order_status = 'delivered' and o.order_delivered_customer_date is not null then
                round(extract(epoch from (o.order_delivered_customer_date - o.order_purchase_timestamp))::numeric / 86400.0, 2)
            else null
        end as days_to_deliver,

        round(extract(epoch from (o.order_estimated_delivery_date - o.order_purchase_timestamp))::numeric / 86400.0, 2) as days_estimated,

        -- Delivery delay in days: actual delivery date minus estimated date (>0 late, <=0 on-time)
        case 
            when o.order_status = 'delivered' and o.order_delivered_customer_date is not null then
                round(extract(epoch from (o.order_delivered_customer_date - o.order_estimated_delivery_date))::numeric / 86400.0, 2)
            else null
        end as delivery_delay_days,

        -- Process breakdown durations (in days)
        case 
            when o.order_approved_at is not null then
                round(extract(epoch from (o.order_approved_at - o.order_purchase_timestamp))::numeric / 86400.0, 2)
            else null
        end as days_purchase_to_approval,

        case 
            when o.order_delivered_carrier_date is not null and o.order_approved_at is not null then
                round(extract(epoch from (o.order_delivered_carrier_date - o.order_approved_at))::numeric / 86400.0, 2)
            else null
        end as days_approval_to_carrier,

        case 
            when o.order_delivered_customer_date is not null and o.order_delivered_carrier_date is not null then
                round(extract(epoch from (o.order_delivered_customer_date - o.order_delivered_carrier_date))::numeric / 86400.0, 2)
            else null
        end as days_carrier_to_delivery,

        -- Item aggregates
        coalesce(items.total_items, 0) as total_items,
        coalesce(items.total_order_price, 0) as total_order_price,
        coalesce(items.total_freight_value, 0) as total_freight_value,
        (coalesce(items.total_order_price, 0) + coalesce(items.total_freight_value, 0)) as total_order_value

    from orders o
    inner join customers c
        on o.customer_id = c.customer_id
    left join order_items_agg items
        on o.order_id = items.order_id
)

select * from final
