{{ config(materialized = 'view') }}

-- ============================================================
-- Intermediate Model: Oncology Cost Profiling
--
-- Purpose:
--   Analyze where oncology spend is going by care setting
--   using bill type codes + revenue center codes.
--
-- Grain:
--   One row per claim
--
-- Notes:
--   - All oncology claims are institutional
--   - Revenue center overrides bill type for ED
-- ============================================================

with claim_level_costs as (

    select
        claim_id,
        person_id,
        bill_type_code,
        revenue_center_code,

        -- Aggregate financials at the claim level
        sum(paid_amount) as total_paid_amount

    from {{ ref('int_oncology_claims') }}
    group by
        claim_id,
        person_id,
        bill_type_code,
        revenue_center_code
),

classified_claims as (

    select
        *,
        case
            -- Emergency Department (strongest signal)
            when revenue_center_code between '0450' and '0459'
              or revenue_center_code = '0981'
                then 'Emergency Department'

            -- Inpatient (TOB 2nd digit = 1)
            when substr(bill_type_code, 2, 1) = '1'
                then 'Inpatient'

            -- Skilled Nursing Facility
            when substr(bill_type_code, 2, 1) = '2'
                then 'Skilled Nursing Facility'

            -- Outpatient
            when substr(bill_type_code, 2, 1) = '3'
                then 'Outpatient'

            -- Clinic / FQHC
            when substr(bill_type_code, 2, 1) = '7'
                then 'Clinic / FQHC'

            -- Other Institutional (Home Health, Hospice, etc.)
            when substr(bill_type_code, 2, 1) in ('5','8')
                then 'Other Institutional'

            else 'Unknown'
        end as care_setting
    from claim_level_costs
)

select
    care_setting,
    count(distinct claim_id)  as num_claims,
    count(distinct person_id) as num_patients,
    sum(total_paid_amount)    as total_paid_amount,
    avg(total_paid_amount)    as avg_paid_per_claim
from classified_claims
group by care_setting
order by total_paid_amount desc
