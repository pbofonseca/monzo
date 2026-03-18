{{
    config(
        materialized='table',
        partition_by = {"field": "date", "data_type": "date"},
        cluster_by = ["account_id_hashed"]
    )
}}

-- Staging layer: clean raw account_transactions, rename fields, standardize types.
-- Deduplicates on (date, account_id_hashed), because it enforces the grain of the table

with raw_transactions as (

select
    date,
    account_id_hashed,
    transactions_num
from {{ source('monzo_datawarehouse', 'account_transactions') }}

),

deduplicated as (

select
    date,
    account_id_hashed,
    transactions_num,
    row_number() over (
        partition by date, account_id_hashed
        order by transactions_num desc
    ) as rn
from raw_transactions

)

select
    cast(date as date) as date,
    cast(account_id_hashed as string) as account_id_hashed,
    cast(transactions_num as int64) as transactions_num
from deduplicated
where rn = 1