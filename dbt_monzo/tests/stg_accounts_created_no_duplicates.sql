-- Singular test: guarantees stg_accounts_created has no duplicate (account_id_hashed, created_ts).
-- Fails if any row is returned (i.e. if duplicates exist).
select
    account_id_hashed,
    created_ts,
    count(*) as row_count
from {{ ref('stg_accounts_created') }}
group by account_id_hashed, created_ts
having count(*) > 1
