{{ config(
    materialized='view',
    tags=['test_support']
) }}

-- Expected number of rows in dim_account.
-- One row should exist per active account period
-- (created or reopened) in the lifecycle history.

select
    account_id_hashed,
    event_ts as valid_from_at
from {{ ref('int_account_status_history') }}
where account_status in ('created','reopened')