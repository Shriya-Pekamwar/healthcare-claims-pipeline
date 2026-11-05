-- A claim cannot end before it starts
select claim_key, claim_from_date, claim_thru_date
from {{ ref('fct_claims') }}
where claim_thru_date < claim_from_date