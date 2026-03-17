{{ 
    config(
        materialized='incremental',
        partition_by={"field": "activity_day", "data_type": "date"},
        cluster_by=["user_id_hashed"]
    ) 
}}

with user_activity as (

select
    date,
    user_id_hashed
from {{ ref('int_user_activity_daily') }}

{% if is_incremental() %}
--  I count the last 6 days because the window is 7 days. The current day is already included.

where date >= date_sub(
    (select max(activity_day) from {{ this }}),
    interval 6 day
)

{% endif %}

)

select
    user_id_hashed,
    activity_day
from user_activity,
-- Instead of computing range join (7 days), or explicit window function, I unnest the date array, and every time to query metrics, it precompute it once.
unnest(
    generate_date_array(
        date,
        date_add(date, interval 6 day)
    )
) as activity_day