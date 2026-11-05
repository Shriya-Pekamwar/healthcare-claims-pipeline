-- Reconciliation: total payments in the fact must equal total payments in staging.
-- Catches rows dropped or duplicated by joins.
with staged as (
    select coalesce(sum(claim_payment_amount), 0) as total
    from (
        select claim_payment_amount from {{ ref('stg_synpuf__inpatient_claims') }}
        union all
        select claim_payment_amount from {{ ref('stg_synpuf__outpatient_claims') }}
    ) as all_claims
),

fact as (
    select coalesce(sum(claim_payment_amount), 0) as total
    from {{ ref('fct_claims') }}
)

select staged.total as staged_total, fact.total as fact_total
from staged
cross join fact
where abs(staged.total - fact.total) > 0.01