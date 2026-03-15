{{
    config(
        materialized='table',
    )
}}

-- Staging layer: clean raw account_reopened, rename fields, standardize types.
-- Deduplicates on (account_id_hashed, reopened_ts).

with raw_accounts as (
    select
        account_id_hashed,
        reopened_ts
    from {{ source('monzo_datawarehouse', 'account_reopened') }}
),

deduplicated as (
    select
        account_id_hashed,
        reopened_ts,
        row_number() over (
            partition by account_id_hashed, reopened_ts
            order by account_id_hashed, reopened_ts
        ) as _rn
    from raw_accounts
)

select
    cast(account_id_hashed as string) as account_id_hashed,
    cast(reopened_ts as timestamp) as reopened_ts
from deduplicated
where _rn = 1
