{{
    config(
        materialized='table',
        partition_by={"field": "date_day", "data_type": "date"},
        cluster_by=["user_id_hashed"]
    )
}}

with account_ranges as (

select
    user_id_hashed,
    valid_from_date,
    -- If the account is still open, treat it as open until the current date
    -- Using current_date() prevents extending the account lifetime to the end of the calendar (2030)
    -- The calendar definition comes from the dim_date model
    coalesce(valid_to_date, current_date()) as valid_to_date
from {{ ref('dim_account') }}

),

expanded_accounts as (

select
    user_id_hashed,
    date_day
from account_ranges,
-- SCD Type 2 join using the validity period
-- An account is open on date D if D falls within its validity range
unnest(
    generate_date_array(
        valid_from_date,
        valid_to_date
    )
) as date_day

)

-- Multi-account users: a user may have multiple open accounts. Ensure the denominator counts each user only once (distinct)
select distinct
    date_day,
    user_id_hashed
from expanded_accounts