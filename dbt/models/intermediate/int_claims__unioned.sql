with inpatient as (
    select * from {{ ref('stg_synpuf__inpatient_claims') }}
),

outpatient as (
    select * from {{ ref('stg_synpuf__outpatient_claims') }}
),

unioned as (
    select * from inpatient
    union all
    select * from outpatient
)

select
    {{ dbt_utils.generate_surrogate_key(['claim_type', 'claim_id', 'claim_segment']) }} as claim_key,
    *
from unioned