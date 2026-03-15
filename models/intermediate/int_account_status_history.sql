{{
    config(
        materialized='table',
    )
}}

/*
    Account lifecycle events: created, closed, and reopened.
    One row per event, ordered by account and event time.
    Refs: stg_accounts_created, stg_accounts_closed, stg_accounts_reopened.
    See dbt docs: https://docs.getdbt.com/reference/dbt-jinja-functions/ref
*/

with created as (
    -- user_id_hashed and account_type only exist on created; keep null when source has null
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(created_ts as timestamp) as event_ts,
        'created' as account_status,
        cast(user_id_hashed as string) as user_id_hashed,
        cast(account_type as string) as account_type
    from {{ ref('stg_accounts_created') }}
),

closed as (
    -- closed/reopened have no user_id_hashed or account_type; explicitly null
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(closed_ts as timestamp) as event_ts,
        'closed' as account_status,
        cast(null as string) as user_id_hashed,
        cast(null as string) as account_type
    from {{ ref('stg_accounts_closed') }}
),

reopened as (
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(reopened_ts as timestamp) as event_ts,
        'reopened' as account_status,
        cast(null as string) as user_id_hashed,
        cast(null as string) as account_type
    from {{ ref('stg_accounts_reopened') }}
),

unioned as (
    select * from created
    union all
    select * from closed
    union all
    select * from reopened
)

select
    account_id_hashed,
    event_ts,
    account_status,
    user_id_hashed,
    account_type
from unioned
