{{
    config(
        materialized='table',
    )
}}

/*
    dim_account: SCD Type 2 dimension built from int_account_status_history.
    One row per account per "active period" (from created/reopened until closed or current).
    Tracks account lifecycle with valid_from, valid_to, and is_current for point-in-time joins.
*/

with history as (
    select
        account_id_hashed,
        event_ts,
        account_status,
        user_id_hashed,
        account_type
    from {{ ref('int_account_status_history') }}
),

-- Account attributes from the single 'created' event per account
account_attrs as (
    select
        account_id_hashed,
        user_id_hashed,
        account_type
    from history
    where account_status = 'created'
),

-- Period starts: created or reopened
starts as (
    select
        account_id_hashed,
        event_ts as valid_from
    from history
    where account_status in ('created', 'reopened')
),

-- Period ends: closed events
closes as (
    select
        account_id_hashed,
        event_ts as closed_ts
    from history
    where account_status = 'closed'
),

-- Each start gets valid_to = next closed after valid_from (or null if still current)
periods as (
    select
        s.account_id_hashed,
        s.valid_from,
        min(c.closed_ts) as valid_to
    from starts s
    left join closes c
        on s.account_id_hashed = c.account_id_hashed
        and c.closed_ts > s.valid_from
    group by s.account_id_hashed, s.valid_from
),

-- Join periods to account attributes and add SCD Type 2 fields
final as (
    select
        md5(concat(p.account_id_hashed, cast(p.valid_from as string))) as account_sk,
        p.account_id_hashed,
        a.user_id_hashed,
        a.account_type,
        p.valid_from,
        p.valid_to,
        p.valid_to is null as is_current
    from periods p
    inner join account_attrs a on p.account_id_hashed = a.account_id_hashed
)

select
    account_sk,
    account_id_hashed,
    user_id_hashed,
    account_type,
    valid_from,
    valid_to,
    is_current
from final
