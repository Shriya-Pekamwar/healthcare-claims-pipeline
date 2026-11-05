with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2007-01-01' as date)",
        end_date="cast('2011-01-01' as date)"
    ) }}
),

calendar as (
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
),

-- Kimball "unknown member": facts with no usable date point here instead of null
unknown_member as (
    select
        -1                    as date_key,
        cast(null as date)    as calendar_date,
        cast(null as int)     as year,
        cast(null as int)     as quarter,
        cast(null as int)     as month,
        'Unknown'             as month_name,
        cast(null as int)     as day_of_month,
        'Unknown'             as day_name,
        cast(null as boolean) as is_weekend
)

select * from calendar
union all
select * from unknown_member