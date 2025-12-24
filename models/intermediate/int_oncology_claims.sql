-- ============================================================
-- Intermediate model: Oncology claims (claim-level, full lines)
--
-- Purpose:
--   Identify claims associated with cancer diagnoses
--   (ICD-10-CM malignant neoplasm codes C00–C97),
--   and retain ALL claim lines for accurate cost analysis.
--
-- Notes:
--   - Diagnosis positions 1–10 are evaluated
--   - Exploratory analysis showed oncology diagnoses
--     appear primarily within the first 9 positions
--   - All claim lines are retained once a claim
--     has at least one cancer diagnosis
-- ============================================================

{{ config(materialized='view') }}

with cancer_claims as (

    -- --------------------------------------------------------
    -- Identify claims with ANY cancer diagnosis (dx1–dx10)
    -- --------------------------------------------------------
    select distinct
        claim_id
    from input_layer.medical_claim
    where diagnosis_code_type = 'icd-10-cm'
      and (
           diagnosis_code_1  like 'C%'
        or diagnosis_code_2  like 'C%'
        or diagnosis_code_3  like 'C%'
        or diagnosis_code_4  like 'C%'
        or diagnosis_code_5  like 'C%'
        or diagnosis_code_6  like 'C%'
        or diagnosis_code_7  like 'C%'
        or diagnosis_code_8  like 'C%'
        or diagnosis_code_9  like 'C%'
        or diagnosis_code_10 like 'C%'
      )
)

select
    -- --------------------------------------------------------
    -- Identifiers
    -- --------------------------------------------------------
    mc.claim_id,
    mc.claim_line_number,
    mc.person_id,
    mc.member_id,

    -- --------------------------------------------------------
    -- Diagnosis context (retain for transparency)
    -- --------------------------------------------------------
    mc.diagnosis_code_type,
    mc.diagnosis_code_1,
    mc.diagnosis_code_2,
    mc.diagnosis_code_3,
    mc.diagnosis_code_4,
    mc.diagnosis_code_5,
    mc.diagnosis_code_6,
    mc.diagnosis_code_7,
    mc.diagnosis_code_8,
    mc.diagnosis_code_9,
    mc.diagnosis_code_10,

    -- --------------------------------------------------------
    -- Dates (service, claim, payment)
    -- --------------------------------------------------------
    mc.claim_start_date,
    mc.claim_end_date,
    mc.claim_line_start_date,
    mc.claim_line_end_date,
    mc.admission_date,
    mc.discharge_date,
    mc.paid_date,

    -- --------------------------------------------------------
    -- Care setting / classification
    -- --------------------------------------------------------
    mc.claim_type,
    mc.place_of_service_code,
    mc.bill_type_code,
    mc.revenue_center_code,
    mc.drg_code,

    -- --------------------------------------------------------
    -- Financials (line-level; aggregated downstream)
    -- --------------------------------------------------------
    mc.paid_amount,
    mc.allowed_amount,
    mc.charge_amount,
    mc.total_cost_amount,

    -- --------------------------------------------------------
    -- Metadata
    -- --------------------------------------------------------
    mc.payer,
    mc.plan,
    mc.in_network_flag,
    mc.data_source,
    mc.file_name,
    mc.file_date,
    mc.ingest_datetime

from input_layer.medical_claim mc
inner join cancer_claims cc
    on mc.claim_id = cc.claim_id
