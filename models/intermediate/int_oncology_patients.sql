{{ config(materialized = 'view') }}

-- ============================================================
-- Intermediate Model: int_oncology_patients
--
-- Purpose:
--   Patient-level oncology table that:
--   1) Identifies cancer diagnoses using ICD-10-CM codes
--   2) Retains cancer-type indicator flags
--   3) Assigns a single primary cancer category using
--      hierarchical precedence rules
--   4) Adds aggregated cost and utilization context
--
-- Grain:
--   One row per person_id
-- ============================================================

with exploded_diagnoses as (

    -- --------------------------------------------------------
    -- Explode diagnosis codes (1–10) to row-level
    -- --------------------------------------------------------
    select
        person_id,
        unnest([
            diagnosis_code_1,
            diagnosis_code_2,
            diagnosis_code_3,
            diagnosis_code_4,
            diagnosis_code_5,
            diagnosis_code_6,
            diagnosis_code_7,
            diagnosis_code_8,
            diagnosis_code_9,
            diagnosis_code_10
        ]) as diagnosis_code
    from {{ ref('int_oncology_claims') }}

),

cancer_flags as (

    -- --------------------------------------------------------
    -- Derive cancer-type indicator flags at patient level
    -- --------------------------------------------------------
    select
        person_id,

        max(case when diagnosis_code between 'C77' and 'C79' then 1 else 0 end)
            as has_metastatic,

        max(case when diagnosis_code between 'C81' and 'C96' then 1 else 0 end)
            as has_hematologic,

        max(case when diagnosis_code like 'C50%' then 1 else 0 end)
            as has_breast,

        max(case when diagnosis_code like 'C61%' then 1 else 0 end)
            as has_prostate,

        max(case when diagnosis_code like 'C34%' then 1 else 0 end)
            as has_lung,

        max(case when diagnosis_code like 'C73%' then 1 else 0 end)
            as has_thyroid

    from exploded_diagnoses
    where diagnosis_code like 'C%'
    group by person_id
),

patient_cost_summary as (

    -- --------------------------------------------------------
    -- Aggregate cost, utilization, and timing at patient level
    -- --------------------------------------------------------
    select
        person_id,

        -- Financial aggregates
        sum(paid_amount) as total_paid_amount,
        sum(allowed_amount) as total_allowed_amount,
        sum(charge_amount) as total_charge_amount,

        -- Time boundaries (using claim line dates)
        min(claim_start_date) as first_cancer_claim_date,
        max(claim_end_date) as last_cancer_claim_date,

        -- Utilization
        count(distinct claim_id) as num_claims

    from {{ ref('int_oncology_claims') }}
    group by person_id
)

-- ------------------------------------------------------------
-- Final patient-level oncology table
-- ------------------------------------------------------------
select
    f.person_id,

    -- Cancer flags (diagnostic transparency)
    f.has_metastatic,
    f.has_hematologic,
    f.has_breast,
    f.has_prostate,
    f.has_lung,
    f.has_thyroid,

    -- Primary cancer category (hierarchical precedence)
    case
        when f.has_metastatic = 1 then 'Metastatic / Secondary'
        when f.has_hematologic = 1 then 'Hematologic'
        when f.has_breast = 1 then 'Breast'
        when f.has_prostate = 1 then 'Prostate'
        when f.has_lung = 1 then 'Lung'
        when f.has_thyroid = 1 then 'Thyroid'
        else 'Other Solid Tumors'
    end as cancer_type,

    -- Aggregated cost & utilization context
    s.total_paid_amount,
    s.total_allowed_amount,
    s.total_charge_amount,
    s.first_cancer_claim_date,
    s.last_cancer_claim_date,
    s.num_claims

from cancer_flags f
left join patient_cost_summary s
  on f.person_id = s.person_id
