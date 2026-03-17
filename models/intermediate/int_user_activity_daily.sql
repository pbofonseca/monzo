{{ 
    config(
        materialized='table',
        partition_by={"field": "date", "data_type": "date"},
        cluster_by=["user_id_hashed"]
    ) 
}}

-- Creates one row per user per day with activity
-- It doesn't matter transaction counts anymore, only user activity presence

WITH account_activity AS (

SELECT
    t.date,
    acc.user_id_hashed
FROM {{ ref('stg_accounts_transactions') }} t

JOIN {{ ref('dim_account') }} acc
    ON t.account_id_hashed = acc.account_id_hashed
    AND t.date >= acc.valid_from_date
    AND (t.date <= acc.valid_to_date OR acc.valid_to_date IS NULL)

WHERE t.transactions_num > 0

)

SELECT DISTINCT
    date,
    user_id_hashed
FROM account_activity