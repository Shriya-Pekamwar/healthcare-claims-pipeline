with source as (
    select * from {{ source('synpuf_bronze', 'outpatient_claims') }}
),

renamed as (
    select
        'outpatient'                                    as claim_type,
        {{ clean_string('clm_id') }}                    as claim_id,
        {{ to_int('segment') }}                         as claim_segment,
        {{ clean_string('desynpuf_id') }}               as beneficiary_id,
        {{ clean_string('prvdr_num') }}                 as provider_id,
        {{ parse_date('clm_from_dt') }}                 as claim_from_date,
        {{ parse_date('clm_thru_dt') }}                 as claim_thru_date,
        cast(null as date)                              as admission_date,
        cast(null as date)                              as discharge_date,
        {{ clean_string('at_physn_npi') }}              as attending_npi,
        cast(null as string)                            as drg_code,
        {{ clean_string('admtng_icd9_dgns_cd') }}       as admitting_diagnosis_code,
        {{ to_decimal('clm_pmt_amt') }}                 as claim_payment_amount,
        {{ to_decimal('nch_prmry_pyr_clm_pd_amt') }}    as primary_payer_paid_amount,
        cast(null as int)                               as utilization_days,
        {% for i in range(1, 11) -%}
        {{ clean_string('icd9_dgns_cd_' ~ i) }}         as diagnosis_code_{{ i }},
        {% endfor -%}
        _source_file,
        _ingested_at
    from source
)

select * from renamed