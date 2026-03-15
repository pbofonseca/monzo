{{ config(materialized='table') }}

{# Date dimension for reporting; range covers typical analytics needs. #}
{{ dbt_date.get_date_dimension('2020-01-01', '2030-12-31') }}
