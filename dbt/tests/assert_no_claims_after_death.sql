{{ config(severity='warn') }}
-- Claims dated after the beneficiary's recorded death date
select f.claim_key, f.claim_from_date, b.death_date
from {{ ref('fct_claims') }} f
join {{ ref('dim_beneficiary') }} b on f.beneficiary_key = b.beneficiary_key
where b.death_date is not null
  and f.claim_from_date > b.death_date