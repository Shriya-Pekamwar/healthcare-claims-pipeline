with claims as (
    select
        claim_key,
        {% for i in range(1, 11) -%}
        diagnosis_code_{{ i }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from {{ ref('int_claims__unioned') }}
)

select
    claim_key,
    diagnosis_position,
    diagnosis_code
from claims
lateral view stack(
    10,
    {% for i in range(1, 11) -%}
    {{ i }}, diagnosis_code_{{ i }}{% if not loop.last %},{% endif %}
    {% endfor %}
) d as diagnosis_position, diagnosis_code
where diagnosis_code is not null