with delivery as (
    select
        customer_state,
        count(*) as total_orders,
        count(*) filter (where is_delivered) as delivered_orders,
        count(*) filter (where is_delivered and is_on_time) as on_time_orders,
        round(count(*) filter (where is_delivered and is_on_time)::numeric / nullif(count(*) filter (where is_delivered), 0) * 100, 2) as on_time_rate_pct,
        round(avg(days_to_deliver) filter (where is_delivered), 2) as avg_delivery_days,
        round(avg(days_estimated) filter (where is_delivered), 2) as avg_estimated_days,
        round(avg(delivery_delay_days) filter (where is_delivered), 2) as avg_delay_days
    from {{ ref('mart_delivery_performance') }}
    group by customer_state
),

freight as (
    select
        customer_state,
        count(*) as total_items,
        round(sum(price), 2) as total_price,
        round(sum(freight_value), 2) as total_freight,
        round(sum(freight_value) / nullif(sum(price), 0), 4) as freight_ratio,
        round((sum(freight_value) / nullif(sum(price), 0)) * 100.0, 2) as freight_ratio_pct,
        round(avg(freight_value), 2) as avg_freight_per_item
    from {{ ref('mart_order_items_enriched') }}
    group by customer_state
)

select
    d.customer_state,
    d.total_orders,
    d.delivered_orders,
    d.on_time_orders,
    d.on_time_rate_pct,
    d.avg_delivery_days,
    d.avg_estimated_days,
    d.avg_delay_days,
    f.total_items,
    f.total_price,
    f.total_freight,
    f.freight_ratio_pct,
    f.avg_freight_per_item
from delivery d
inner join freight f
    on d.customer_state = f.customer_state

