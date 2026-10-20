{% macro clean_string(col) -%}
    nullif(trim({{ col }}), '')
{%- endmacro %}

{% macro parse_date(col, fmt='yyyyMMdd') -%}
    cast(try_to_timestamp({{ clean_string(col) }}, '{{ fmt }}') as date)
{%- endmacro %}

{% macro to_decimal(col, precision=12, scale=2) -%}
    try_cast({{ clean_string(col) }} as decimal({{ precision }}, {{ scale }}))
{%- endmacro %}

{% macro to_int(col) -%}
    try_cast({{ clean_string(col) }} as int)
{%- endmacro %}