{{
    config(
        materialized='table',
    )
}}

-- Staging layer: clean raw account_closed, rename fields, standardize types.
-- Deduplicates on (account_id_hashed, closed_ts).

with raw_accounts as (
    select
        account_id_hashed,
        closed_ts
    from {{ source('monzo_datawarehouse', 'account_closed') }}
),

deduplicated as (
    select
        account_id_hashed,
        closed_ts,
        row_number() over (
            partition by account_id_hashed, closed_ts
            order by account_id_hashed, closed_ts
        ) as _rn
    from raw_accounts
)

select
    cast(account_id_hashed as string) as account_id_hashed,
    cast(closed_ts as timestamp) as closed_ts
from deduplicated
where _rn = 1
