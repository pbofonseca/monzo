-- Singular test: guarantees stg_accounts_reopened has no duplicate (account_id_hashed, reopened_ts).
-- Fails if any row is returned (i.e. if duplicates exist).
select
    account_id_hashed,
    reopened_ts,
    count(*) as row_count
from {{ ref('stg_accounts_reopened') }}
group by account_id_hashed, reopened_ts
having count(*) > 1
