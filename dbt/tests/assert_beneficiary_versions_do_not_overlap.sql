-- SCD2 integrity: a beneficiary's version date ranges must never overlap
select a.beneficiary_id, a.version_number, b.version_number as overlapping_version
from {{ ref('dim_beneficiary') }} a
join {{ ref('dim_beneficiary') }} b
  on  a.beneficiary_id = b.beneficiary_id
  and a.version_number < b.version_number
  and a.valid_to > b.valid_from