with orders_perf as (
    select * from {{ ref('mart_delivery_performance') }}
),

daily_agg as (
    select * from {{ ref('mart_delivery_daily') }}
)

select
    -- 1. Order Identifiers & Geography
    p.order_id,
    p.customer_id,
    p.customer_unique_id,
    p.customer_zip_code_prefix,
    p.customer_city,
    p.customer_state,
    p.order_status,
    p.is_canceled,

    -- 2. Order Timestamps
    p.order_purchase_timestamp,
    p.order_purchase_date,
    p.order_approved_at,
    p.order_delivered_carrier_date,
    p.order_delivered_customer_date,
    p.order_estimated_delivery_date,

    -- 3. Order-Grain Delivery KPIs
    p.is_delivered,
    p.is_on_time,
    p.days_to_deliver,
    p.days_estimated,
    p.delivery_delay_days,
    p.days_purchase_to_approval,
    p.days_approval_to_carrier,
    p.days_carrier_to_delivery,
    p.total_items,
    p.total_order_price,
    p.total_freight_value,
    p.total_order_value,

    -- 4. State & Date Benchmark Metrics (from mart_delivery_daily)
    d.total_orders as state_daily_total_orders,
    d.delivered_orders as state_daily_delivered_orders,
    d.on_time_orders as state_daily_on_time_orders,
    d.late_orders as state_daily_late_orders,
    d.on_time_delivery_rate as state_daily_on_time_rate,
    d.cancellation_rate as state_daily_cancellation_rate,
    d.avg_days_to_deliver as state_daily_avg_delivery_days,
    d.avg_days_estimated as state_daily_avg_estimated_days,
    d.avg_delivery_delay_days as state_daily_avg_delay_days,
    d.total_revenue as state_daily_total_revenue,

    -- 5. Variance Metric (relative to state-daily benchmark)
    round((p.days_to_deliver - d.avg_days_to_deliver), 2) as diff_from_state_daily_avg_days

from orders_perf p
left join daily_agg d
    on p.order_purchase_date = d.purchase_date
    and p.customer_state = d.customer_state

