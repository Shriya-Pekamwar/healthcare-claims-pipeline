-- Undated claims are a known source issue (~1.3%). Fail if the rate jumps,
-- which would indicate a new upstream problem rather than the known one.
select
    count_if(is_undated) as undated_claims,
    count(*)             as total_claims
from {{ ref('fct_claims') }}
having count_if(is_undated) > 0.02 * count(*)