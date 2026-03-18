{{
    config(
        materialized='incremental',
        partition_by={"field": "date_day", "data_type": "date"},
        cluster_by=["user_id_hashed"],
        unique_key=["date_day", "user_id_hashed"]
    )
}}

-- The goal of this model is to represent users with at least one open account on each day
-- Grain: (date_day, user_id_hashed)
-- This is used as the denominator for user-based metrics

-- Important:
-- This model expands SCD Type 2 ranges into daily records.
-- To avoid rewriting the entire history on each run (which would exceed BigQuery partition limits),
-- we restrict the expansion to a recent time window during incremental runs.

{% set repair_window_days = 30 %}

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

            -- Limit the start of the expansion window
            -- Full refresh: use full history
            -- Incremental: only expand recent days to avoid partition explosion
            greatest(
                valid_from_date,
                {% if is_incremental() %}
                    date_sub(current_date(), interval {{ repair_window_days }} day)
                {% else %}
                    valid_from_date
                {% endif %}
            ),

            valid_to_date

        )
    ) as date_day

)

-- Multi-account users: a user may have multiple open accounts.
-- Ensure the denominator counts each user only once per day
select distinct
    date_day,
    user_id_hashed
from expanded_accounts