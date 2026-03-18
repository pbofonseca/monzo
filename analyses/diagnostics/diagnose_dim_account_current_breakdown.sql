{{ config(
    materialized='view',
    tags=['diagnostic']
) }}

-- Diagnostic model
-- Shows how many accounts violate the one current row per account
-- For more details, see the documentation in the models/diagnostics/diagnose_dim_account_current_breakdown.yml file 
-- and the documentation in the docs/diagnose_dim_account_current_breakdown.md file

with current_per_account as (

select
    account_id_hashed,
    countif(is_current) as current_count
from {{ ref('dim_account') }}
group by account_id_hashed

),

violations as (

select
    current_count,
    count(*) as number_of_accounts
from current_per_account
where current_count != 1
group by current_count

)

select *
from violations
order by current_count