{{
    config(
        materialized='table',
    )
}}

/*
    Account lifecycle events: created, closed, and reopened.
    One row per event, ordered by account and event time.
*/

with created as (
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(created_ts as timestamp) as event_ts,
        'created' as event_type,
        cast(user_id_hashed as string) as user_id_hashed,
        cast(account_type as string) as account_type
    from {{ ref('stg_accounts_created') }}
),

closed as (
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(closed_ts as timestamp) as event_ts,
        'closed' as event_type,
        cast(null as string) as user_id_hashed,
        cast(null as string) as account_type
    from {{ ref('stg_accounts_closed') }}
),

reopened as (
    select
        cast(account_id_hashed as string) as account_id_hashed,
        cast(reopened_ts as timestamp) as event_ts,
        'reopened' as event_type,
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
    event_type,
    user_id_hashed,
    account_type
from unioned
