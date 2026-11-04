select distinct
    diagnosis_code,
    left(diagnosis_code, 3) as diagnosis_category,
    case
        when diagnosis_code like 'V%' then 'Supplementary (V code)'
        when diagnosis_code like 'E%' then 'External cause (E code)'
        else 'Disease or injury'
    end                     as code_type
from {{ ref('int_claims__diagnoses') }}