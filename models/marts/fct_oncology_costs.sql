{{ config(materialized = 'table') }}

-- ============================================================
-- MART: fct_oncology_cost
--
-- Purpose:
--   Cost profiling for oncology spend.
--   Breaks down total paid amounts by care setting.
--
-- Grain:
--   One row per care_setting
--
-- Source:
--   int_oncology_costs
-- ============================================================

select
    care_setting,

    -- utilization
    num_claims,
    num_patients,

    -- cost metrics
    round(total_paid_amount,2) as total_paid,
    round(avg_paid_per_claim,2) as avg_paid_per_claim

from {{ ref('int_oncology_costs') }}