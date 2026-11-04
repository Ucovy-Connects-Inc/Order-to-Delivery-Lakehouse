with source as (
    select * from {{ source('bronze', 'olist_order_payments_dataset') }}
),

renamed_and_cleaned as (
    select
        order_id,
        cast(payment_sequential as integer) as payment_sequential,
        lower(trim(payment_type)) as payment_type,
        cast(payment_installments as integer) as payment_installments,
        cast(payment_value as numeric(10, 2)) as payment_value,
        -- Deduplication on natural key (order_id + payment_sequential)
        row_number() over (
            partition by order_id, payment_sequential
            order by _dlt_load_id desc
        ) as row_num
    from source
)

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
from renamed_and_cleaned
where row_num = 1

