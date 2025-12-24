{{ config(materialized = 'view') }}

-- ============================================================
-- FACT MART: Oncology Cost Drivers by Cancer Type
--
-- Grain:
--   cancer_type x care_setting
--
-- Purpose:
--   Summarize prevalence and cost drivers across cancers
-- ============================================================

with claims as (

    select
        c.claim_id,
        c.person_id,
        c.bill_type_code,
        c.revenue_center_code,
        sum(c.paid_amount) as paid_amount

    from {{ ref('int_oncology_claims') }} c
    group by
        c.claim_id,
        c.person_id,
        c.bill_type_code,
        c.revenue_center_code
),

classified_claims as (

    select
        *,
        case
            when revenue_center_code between '0450' and '0459'
              or revenue_center_code = '0981'
                then 'Emergency Department'
            when substr(bill_type_code, 2, 1) = '1'
                then 'Inpatient'
            when substr(bill_type_code, 2, 1) = '3'
                then 'Outpatient'
            else 'Other'
        end as care_setting
    from claims
),

patients as (

    select
        person_id,
        cancer_type
    from {{ ref('int_oncology_patients') }}
)

select
    p.cancer_type,
    c.care_setting,

    count(distinct c.person_id) as num_patients,
    count(distinct c.claim_id) as num_claims,
    round(sum(c.paid_amount), 2) as total_paid_amount,
    round(avg(c.paid_amount), 2) as avg_paid_per_claim

from classified_claims c
join patients p
    on c.person_id = p.person_id

group by
    p.cancer_type,
    c.care_setting

order by
    total_paid_amount desc
