{{
    config(
        materialized='view',
        tags=['diagnostic'],
    )
}}
/*
  Diagnostic only: breakdown of accounts failing "one current per account" test.
  current_count = 0 → closed-only accounts (no open period). current_count >= 2 → multiple open periods (e.g. reopened without a close).
*/
with current_per_account as (
    select
        account_id_hashed,
        countif(is_current) as current_count
    from {{ ref('dim_account') }}
    group by account_id_hashed
),
violations as (
    select current_count, count(*) as num_accounts
    from current_per_account
    where current_count != 1
    group by current_count
    order by current_count
)
select * from violations
