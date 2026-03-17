-- The incremental strategy is to compute the metric for the last 7 days
-- Because the metric depends on a 7-day rolling window, activity from a given day affects the following 6 days
-- However, late-arriving transactions may appear after the original computation
-- To protect the metric from these late events, incremental runs recompute a repair window of the last 14 days
-- If we did not recompute this window, late events could permanently corrupt historical metrics
-- Data before the repair window is never modified. This guarantees that historical values remain stable and reproducible

{{ 
    config(
        materialized='incremental',
        partition_by={"field": "date_day", "data_type": "date"},
        cluster_by=["date_day"]
    ) 
}}

-- The main goal is to compute the seven_day_active_rate
-- Denominator: users_with_open_account (users who had at least one open account on that day)
-- Numerator: users with at least one transaction in the last 7 days
-- seven_day_active_rate = seven_day_active_users / users_with_open_account

with date_range as (

-- The fact table should only compute dates where activity could exist
-- Earliest metric date: min(transaction_date) - 6 days, since the rolling window requires the previous 6 days of data
-- Without this restriction, the query would generate partitions for the entire calendar 
-- (e.g., up to 2030), exceeding BigQuery's 4,000 partition write limit
-- It is a trick one needs to know!
-- The error that I faced: 
-- Database Error in model fct_user_metrics_daily (models/marts/fct_user_metrics_daily.sql)
--   Too many partitions produced by query, allowed 4000, query produces at least 4088 partitions.
--   compiled code at target/run/dbt_monzo/models/marts/fct_user_metrics_daily.sql
select date_day
from {{ ref('dim_date') }}

where date_day between
    date_sub((select min(date) from {{ ref('int_user_activity_daily') }}), interval 6 day)
    and current_date()

{% if is_incremental() %}

-- Incremental repair window recompute the last 14 days relative to the latest stored partition
-- The window is larger than the 7-day metric window to capture late-arriving events
-- Otherwise, transactions arriving 8–13 days late could permanently distort the metric
and date_day >= date_sub(
    (
        select coalesce(max(date_day), date '1900-01-01')
        from {{ this }}
    ),
    interval 14 day
)

{% endif %}

),

-- Users who performed at least one transaction on a given day
daily_active_users as (

select
    date as date_day,
    count(distinct user_id_hashed) as daily_active_users
from {{ ref('int_user_activity_daily') }}
group by date

),

-- Users who performed at least one transaction in the last 7 days
users_active_last_seven_days as (

-- Rolling window join uses D-6 -> D range
-- Restricting the computation to date_range prevents scanning the entire activity table for every calendar day
select
    d.date_day,
    count(distinct a.user_id_hashed) as users_active_last_seven_days
from date_range d
left join {{ ref('int_user_activity_daily') }} a
    on a.date >= date_sub(d.date_day, interval 6 day)
   and a.date <= d.date_day
group by d.date_day

),

users_with_open_account as (

-- Users with at least one open account on that day (the full population for the period)
-- The table is already built at grain (date_day, user_id_hashed)
-- so counting distinct users provides the correct denominator for the metric
select
    date_day,
    count(distinct user_id_hashed) as users_with_open_account
from {{ ref('int_open_users_daily') }}
group by date_day

)

select
    d.date_day,

    coalesce(daily_active_users.daily_active_users,0) as daily_active_users,

    coalesce(users_active_last_seven_days.users_active_last_seven_days,0) as seven_day_active_users,

    coalesce(users_with_open_account.users_with_open_account,0) as users_with_open_account,

    -- Ensure the metric remains deterministic and null-safe (take home test exigency)
    -- No activity -> numerator = 0
    -- No users with open accounts -> denominator = NULL (prevents division by zero)
    safe_divide(
        coalesce(users_active_last_seven_days.users_active_last_seven_days,0),
        nullif(users_with_open_account.users_with_open_account,0)
    ) as seven_day_active_rate

from date_range d

left join daily_active_users
    on d.date_day = daily_active_users.date_day

left join users_active_last_seven_days
    on d.date_day = users_active_last_seven_days.date_day

left join users_with_open_account
    on d.date_day = users_with_open_account.date_day