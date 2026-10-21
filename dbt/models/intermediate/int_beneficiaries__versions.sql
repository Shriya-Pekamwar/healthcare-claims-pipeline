{% set tracked_attributes = ['death_date', 'state_code', 'county_code', 'has_esrd']
                            + var('chronic_conditions') %}

with yearly as (
    select
        *,
        -- One hash summarizing all tracked attributes for this beneficiary-year
        {{ dbt_utils.generate_surrogate_key(tracked_attributes) }} as attribute_hash
    from {{ ref('stg_synpuf__beneficiaries') }}
),

flagged as (
    -- 1 when this year's attributes differ from the previous year (or it's the first year)
    select
        *,
        case
            when lag(attribute_hash) over (
                partition by beneficiary_id order by coverage_year
            ) = attribute_hash then 0
            else 1
        end as is_new_version
    from yearly
),

numbered as (
    -- Running total of change flags = version number
    select
        *,
        sum(is_new_version) over (
            partition by beneficiary_id
            order by coverage_year
            rows between unbounded preceding and current row
        ) as version_number
    from flagged
),

versions as (
    -- Collapse consecutive unchanged years into one version
    select
        beneficiary_id,
        version_number,
        min(coverage_year) as first_coverage_year,
        max(coverage_year) as last_coverage_year,
        max(birth_date)    as birth_date,
        max(sex)           as sex,
        max(race)          as race,
        {% for attr in tracked_attributes -%}
        max({{ attr }})    as {{ attr }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from numbered
    group by beneficiary_id, version_number
)

select
    *,
    -- First version is open-ended in the past so early claims still match a profile
    case
        when version_number = 1 then date'1900-01-01'
        else make_date(first_coverage_year, 1, 1)
    end as valid_from,
    coalesce(
        lead(make_date(first_coverage_year, 1, 1)) over (
            partition by beneficiary_id order by version_number
        ),
        date'9999-12-31'
    ) as valid_to
from versions