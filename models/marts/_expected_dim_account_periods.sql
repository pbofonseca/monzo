{{
    config(
        materialized='view',
        tags=['test_support'],
    )
}}
/*
  Expected row count for dim_account: one row per active period (created or reopened).
  Used by dbt_expectations.expect_table_row_count_to_equal_other_table to reconcile
  dim_account row count with int_account_status_history. See docs/MART_TESTING_OUTLINE.md §2.
*/
with history as (
    select
        account_id_hashed,
        event_ts,
        account_status
    from {{ ref('int_account_status_history') }}
),

starts as (
    select
        account_id_hashed,
        event_ts as valid_from_at
    from history
    where account_status in ('created', 'reopened')
)

select account_id_hashed, valid_from_at from starts
