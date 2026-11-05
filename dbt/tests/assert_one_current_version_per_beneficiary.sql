-- SCD2 integrity: exactly one current version per beneficiary
select beneficiary_id, sum(case when is_current then 1 else 0 end) as current_versions
from {{ ref('dim_beneficiary') }}
group by beneficiary_id
having sum(case when is_current then 1 else 0 end) != 1