with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2007-01-01' as date)",
        end_date="cast('2011-01-01' as date)"
    ) }}
)

select
    cast(date_format(date_day, 'yyyyMMdd') as int) as date_key,
    cast(date_day as date)                          as calendar_date,
    year(date_day)                                  as year,
    quarter(date_day)                               as quarter,
    month(date_day)                                 as month,
    date_format(date_day, 'MMMM')                   as month_name,
    dayofmonth(date_day)                            as day_of_month,
    date_format(date_day, 'EEEE')                   as day_name,
    dayofweek(date_day) in (1, 7)                   as is_weekend
from spine