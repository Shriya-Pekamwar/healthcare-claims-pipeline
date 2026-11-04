select
    claim_key,
    diagnosis_code,
    diagnosis_position,
    diagnosis_position = 1 as is_principal_diagnosis
from {{ ref('int_claims__diagnoses') }}