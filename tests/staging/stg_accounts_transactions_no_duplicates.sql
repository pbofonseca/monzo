-- Singular test: guarantees stg_accounts_transactions has no duplicate (date, account_id_hashed).
-- Fails if any row is returned (i.e. if duplicates exist).
select
    date,
    account_id_hashed,
    count(*) as row_count
from {{ ref('stg_accounts_transactions') }}
group by date, account_id_hashed
having count(*) > 1
