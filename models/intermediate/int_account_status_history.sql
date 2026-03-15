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
    -- user_id_hashed and account_type only on created. Null from source = not_informed.
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(created_ts as timestamp) as event_ts,
        'created' as account_status,
        coalesce(cast(user_id_hashed as string), 'not_informed') as user_id_hashed,
        coalesce(cast(account_type as string), 'not_informed') as account_type
    from {{ ref('stg_accounts_created') }}
),

closed as (
    -- closed/reopened: no user_id_hashed or account_type in schema; not_applied (dim gets these from created).
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(closed_ts as timestamp) as event_ts,
        'closed' as account_status,
        'not_applied' as user_id_hashed,
        'not_applied' as account_type
    from {{ ref('stg_accounts_closed') }}
),

reopened as (
    -- same as closed: user_id_hashed and account_type not_applied.
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(reopened_ts as timestamp) as event_ts,
        'reopened' as account_status,
        'not_applied' as user_id_hashed,
        'not_applied' as account_type
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
