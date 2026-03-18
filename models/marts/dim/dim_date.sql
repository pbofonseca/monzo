{{
    config(
        materialized='table',
    )
}}

/*
    dim_date: Date dimension from godatadriven/dbt_date.
    One row per calendar day with day/week/month/quarter/year and prior-year attributes.
    Use for date joins and time-based analytics.
*/
{{ dbt_date.get_date_dimension('2017-01-01', '2030-12-31') }}
