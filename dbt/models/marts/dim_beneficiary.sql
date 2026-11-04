select
    {{ dbt_utils.generate_surrogate_key(['beneficiary_id', 'version_number']) }} as beneficiary_key,
    beneficiary_id,
    version_number,
    birth_date,
    death_date,
    sex,
    race,
    state_code,
    county_code,
    has_esrd,
    {% for condition in var('chronic_conditions') -%}
    {{ condition }},
    {% endfor -%}
    (
        {% for condition in var('chronic_conditions') -%}
        coalesce(cast({{ condition }} as int), 0){% if not loop.last %} +{% endif %}
        {% endfor %}
    )                                     as chronic_condition_count,
    first_coverage_year,
    last_coverage_year,
    valid_from,
    valid_to,
    valid_to = date'9999-12-31'           as is_current
from {{ ref('int_beneficiaries__versions') }}