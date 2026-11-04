with date_series as (
    select
        cast(generate_series('2016-01-01'::date, '2019-12-31'::date, '1 day'::interval) as date) as date_day
)

select
    date_day,
    extract(year from date_day)::integer as year,
    extract(month from date_day)::integer as month,
    to_char(date_day, 'Month') as month_name,
    extract(day from date_day)::integer as day_of_month,
    extract(isodow from date_day)::integer as day_of_week,
    to_char(date_day, 'Day') as day_name,
    extract(quarter from date_day)::integer as quarter,
    case when extract(isodow from date_day) in (6, 7) then true else false end as is_weekend
from date_series

