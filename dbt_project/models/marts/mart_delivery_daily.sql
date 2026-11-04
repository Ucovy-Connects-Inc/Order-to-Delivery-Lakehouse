with delivery_performance as (
    select * from {{ ref('mart_delivery_performance') }}
),

daily_summary as (
    select
        order_purchase_date as purchase_date,
        customer_state,
        
        -- Volume counts
        count(*) as total_orders,
        count(*) filter (where is_delivered) as delivered_orders,
        count(*) filter (where is_canceled) as canceled_orders,
        count(*) filter (where is_delivered and is_on_time) as on_time_orders,
        count(*) filter (where is_delivered and not is_on_time) as late_orders,

        -- Rates (on-time rate strictly calculated on delivered orders only)
        case 
            when count(*) filter (where is_delivered) > 0 then
                round(
                    (count(*) filter (where is_delivered and is_on_time)::numeric / count(*) filter (where is_delivered)::numeric) * 100.0,
                    2
                )
            else null 
        end as on_time_delivery_rate,

        case 
            when count(*) > 0 then
                round(
                    (count(*) filter (where is_canceled)::numeric / count(*)::numeric) * 100.0,
                    2
                )
            else 0.0
        end as cancellation_rate,

        -- Durations (delivered orders only)
        round(avg(days_to_deliver) filter (where is_delivered), 2) as avg_days_to_deliver,
        round(avg(days_estimated) filter (where is_delivered), 2) as avg_days_estimated,
        round(avg(delivery_delay_days) filter (where is_delivered), 2) as avg_delivery_delay_days,
        round(avg(days_purchase_to_approval) filter (where is_delivered), 2) as avg_days_purchase_to_approval,
        round(avg(days_approval_to_carrier) filter (where is_delivered), 2) as avg_days_approval_to_carrier,
        round(avg(days_carrier_to_delivery) filter (where is_delivered), 2) as avg_days_carrier_to_delivery,

        -- Financial aggregates
        sum(total_items) as total_items_sold,
        round(sum(total_order_price), 2) as total_revenue,
        round(sum(total_freight_value), 2) as total_freight,
        round(sum(total_order_value), 2) as total_order_value

    from delivery_performance
    group by order_purchase_date, customer_state
)

select * from daily_summary

