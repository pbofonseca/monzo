/*
  Diagnostic: breakdown of accounts failing "one current per account".
  Run after dbt compile; execute the compiled SQL in BigQuery (or use dbt show if you have a model that selects from this logic).
  Result: current_count (0, 2, 3, ...) and num_accounts. Tells you whether failures are mostly 0 current (closed-only) or 2+ current (reopened without close).
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
