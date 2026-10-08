{{ config(materialized='table') }}

SELECT
    visitor_id,
    first_seen_at_utc,
    last_seen_at_utc,
    TO_DATE(first_seen_at_utc) AS first_seen_date,
    TO_DATE(DATE_TRUNC('month', first_seen_at_utc)) AS cohort_month
FROM {{ ref('int_visitors') }}