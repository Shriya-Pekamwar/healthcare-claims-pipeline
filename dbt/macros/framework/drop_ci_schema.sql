{% macro drop_ci_schema() %}
    {% if target.name != 'ci' %}
        {{ exceptions.raise_compiler_error("drop_ci_schema can only run against the 'ci' target") }}
    {% endif %}
    {% set sql %}
        drop schema if exists {{ target.catalog }}.{{ target.schema }} cascade
    {% endset %}
    {% do run_query(sql) %}
    {% do log("Dropped schema " ~ target.catalog ~ "." ~ target.schema, info=true) %}
{% endmacro %}