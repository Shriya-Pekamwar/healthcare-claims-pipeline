{% set years = [2008, 2009, 2010] %}

{% set chronic_condition_map = {
    'sp_alzhdmta': 'has_alzheimers',
    'sp_chf': 'has_chf',
    'sp_chrnkidn': 'has_ckd',
    'sp_cncr': 'has_cancer',
    'sp_copd': 'has_copd',
    'sp_depressn': 'has_depression',
    'sp_diabetes': 'has_diabetes',
    'sp_ischmcht': 'has_ischemic_heart_disease',
    'sp_osteoprs': 'has_osteoporosis',
    'sp_ra_oa': 'has_ra_oa',
    'sp_strketia': 'has_stroke_tia'
} %}

with unioned as (
    {% for y in years %}
    select * from {{ source('synpuf_bronze', 'beneficiary_' ~ y) }}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
),

renamed as (
    select
        desynpuf_id                                   as beneficiary_id,
        cast(source_year as int)                      as coverage_year,
        {{ parse_date('bene_birth_dt') }}             as birth_date,
        {{ parse_date('bene_death_dt') }}             as death_date,
        case bene_sex_ident_cd
            when '1' then 'Male'
            when '2' then 'Female'
            else 'Unknown'
        end                                           as sex,
        -- Race codes per the DE-SynPUF codebook
        case bene_race_cd
            when '1' then 'White'
            when '2' then 'Black'
            when '3' then 'Other'
            when '5' then 'Hispanic'
            else 'Unknown'
        end                                           as race,
        {{ clean_string('sp_state_code') }}           as state_code,
        {{ clean_string('bene_county_cd') }}          as county_code,
        coalesce(bene_esrd_ind = 'Y', false)          as has_esrd,
        {{ to_int('bene_hi_cvrage_tot_mons') }}       as part_a_coverage_months,
        {{ to_int('bene_smi_cvrage_tot_mons') }}      as part_b_coverage_months,
        {{ to_int('bene_hmo_cvrage_tot_mons') }}      as hmo_coverage_months,
        {{ to_int('plan_cvrg_mos_num') }}             as part_d_coverage_months,
        -- Chronic condition flags: '1' = yes, '2' = no
        {% for raw_col, clean_col in chronic_condition_map.items() -%}
        coalesce({{ raw_col }} = '1', false)          as {{ clean_col }},
        {% endfor -%}
        {{ to_decimal('medreimb_ip') }}               as medicare_reimbursement_inpatient,
        {{ to_decimal('medreimb_op') }}               as medicare_reimbursement_outpatient,
        {{ to_decimal('medreimb_car') }}              as medicare_reimbursement_carrier,
        _ingested_at
    from unioned
)

select * from renamed