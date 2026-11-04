with claims as (
    select * from {{ ref('int_claims__unioned') }}
),

beneficiaries as (
    select beneficiary_key, beneficiary_id, valid_from, valid_to
    from {{ ref('dim_beneficiary') }}
),

providers as (
    select provider_key, provider_id
    from {{ ref('dim_provider') }}
),

diagnosis_counts as (
    select claim_key, count(*) as diagnosis_count
    from {{ ref('int_claims__diagnoses') }}
    group by claim_key
)

select
    c.claim_key,
    c.claim_id,
    c.claim_segment,
    c.claim_type,
    b.beneficiary_key,
    p.provider_key,
    cast(date_format(c.claim_from_date, 'yyyyMMdd') as int) as claim_from_date_key,
    cast(date_format(c.claim_thru_date, 'yyyyMMdd') as int) as claim_thru_date_key,
    c.claim_from_date,
    c.claim_thru_date,
    c.drg_code,
    c.claim_payment_amount,
    c.primary_payer_paid_amount,
    c.utilization_days,
    datediff(c.discharge_date, c.admission_date)            as length_of_stay_days,
    coalesce(d.diagnosis_count, 0)                          as diagnosis_count
from claims c
left join beneficiaries b
    on  c.beneficiary_id = b.beneficiary_id
    and c.claim_from_date >= b.valid_from
    and c.claim_from_date <  b.valid_to
left join providers p
    on c.provider_id = p.provider_id
left join diagnosis_counts d
    on c.claim_key = d.claim_key