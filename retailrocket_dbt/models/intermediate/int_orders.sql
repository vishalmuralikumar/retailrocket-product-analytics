{{ config(materialized='view') }}

SELECT
    transaction_id AS order_id,
    MIN(visitor_id) AS visitor_id,
    MIN(event_time_utc) AS order_time_utc,
    MAX(event_time_utc) AS last_purchase_event_time_utc,
    COUNT(*) AS purchase_event_count,
    COUNT(DISTINCT item_id) AS distinct_product_count
FROM {{ ref('stg_events_deduplicated') }}
WHERE event_type = 'transaction'
GROUP BY transaction_id