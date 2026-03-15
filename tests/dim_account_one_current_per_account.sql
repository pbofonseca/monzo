-- SCD Type 2 invariant: each account must have at most one current row (is_current = true).
-- 0 current = closed-only account (created then closed, never reopened) — valid.
-- 2+ current = logic/upstream bug (e.g. reopened without a close) — invalid.
-- See docs/MART_TESTING_OUTLINE.md and docs/FAILED_TESTS_WALKTHROUGH.md

with current_per_account as (
    select
        account_id_hashed,
        countif(is_current) as current_count
    from {{ ref('dim_account') }}
    group by account_id_hashed
)

select account_id_hashed, current_count
from current_per_account
where current_count > 1
