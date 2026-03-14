{{
    config(
        materialized='table',
    )
}}

-- Staging layer: clean raw account_created, rename fields, standardize types.
-- Deduplicates on (account_id_hashed, created_ts).

with raw_accounts as (
    select
        account_id_hashed,
        user_id_hashed,
        account_type,
        created_ts
    from {{ source('monzo_datawarehouse', 'account_created') }}
),

deduplicated as (
    select
        account_id_hashed,
        user_id_hashed,
        account_type,
        created_ts,
        row_number() over (
            partition by account_id_hashed, created_ts
            order by account_id_hashed, created_ts
        ) as _rn
    from raw_accounts
)

select
    cast(account_id_hashed as string) as account_id_hashed,
    cast(user_id_hashed as string) as user_id_hashed,
    cast(account_type as string) as account_type,
    cast(created_ts as timestamp) as created_ts
from deduplicated
where _rn = 1
