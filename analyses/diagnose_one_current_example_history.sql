/*
  Diagnostic: sample of accounts with 2+ current rows.
  Use one of these account_id_hashed in the history query in docs/FAILED_TESTS_WALKTHROUGH.md
  to inspect event_ts and account_status (created/closed/reopened) and see why two periods are "current".
*/
with current_per_account as (
    select
        account_id_hashed,
        countif(is_current) as current_count
    from {{ ref('dim_account') }}
    group by account_id_hashed
)
select account_id_hashed, current_count
from current_per_account
where current_count >= 2
limit 10
