with claims as (
    select * from {{ ref('int_claims__unioned') }}
    where provider_id is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['provider_id']) }}        as provider_key,
    provider_id,
    min(claim_from_date)                                           as first_claim_date,
    max(claim_from_date)                                           as last_claim_date,
    count(*)                                                       as total_claim_segments,
    max(case when claim_type = 'inpatient' then 1 else 0 end) = 1  as serves_inpatient,
    max(case when claim_type = 'outpatient' then 1 else 0 end) = 1 as serves_outpatient
from claims
group by provider_id