-- Singular test: guarantees stg_accounts_closed has no duplicate (account_id_hashed, closed_ts).
-- Fails if any row is returned (i.e. if duplicates exist).
select
    account_id_hashed,
    closed_ts,
    count(*) as row_count
from {{ ref('stg_accounts_closed') }}
group by account_id_hashed, closed_ts
having count(*) > 1
