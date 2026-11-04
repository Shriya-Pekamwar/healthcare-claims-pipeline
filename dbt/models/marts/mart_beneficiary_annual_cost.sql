with claims as (
    select
        f.claim_type,
        f.claim_payment_amount,
        b.beneficiary_id,
        b.chronic_condition_count,
        d.year as claim_year
    from {{ ref('fct_claims') }} f
    join {{ ref('dim_beneficiary') }} b on f.beneficiary_key = b.beneficiary_key
    join {{ ref('dim_date') }} d        on f.claim_from_date_key = d.date_key
)

select
    beneficiary_id,
    claim_year,
    max(chronic_condition_count)                                                as chronic_condition_count,
    count(*)                                                                    as claim_segment_count,
    sum(claim_payment_amount)                                                   as total_payment,
    sum(case when claim_type = 'inpatient'  then claim_payment_amount else 0 end) as inpatient_payment,
    sum(case when claim_type = 'outpatient' then claim_payment_amount else 0 end) as outpatient_payment
from claims
group by beneficiary_id, claim_year