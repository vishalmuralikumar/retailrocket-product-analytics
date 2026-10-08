{{ config(materialized='view') }}

SELECT
    item_id,
    MIN(event_time_utc) AS first_seen_at_utc,
    MAX(event_time_utc) AS last_seen_at_utc,

    COUNT(*) AS total_event_count,
    COUNT(DISTINCT visitor_id) AS interacting_visitor_count,

    COUNT_IF(event_type = 'view') AS view_event_count,
    COUNT_IF(event_type = 'addtocart') AS add_to_cart_event_count,
    COUNT_IF(event_type = 'transaction') AS purchase_event_count,

    COUNT(DISTINCT CASE
        WHEN event_type = 'view' THEN visitor_id
    END) AS viewing_visitor_count,

    COUNT(DISTINCT CASE
        WHEN event_type = 'addtocart' THEN visitor_id
    END) AS cart_visitor_count,

    COUNT(DISTINCT CASE
        WHEN event_type = 'transaction' THEN visitor_id
    END) AS purchasing_visitor_count,

    COUNT(DISTINCT CASE
        WHEN event_type = 'transaction' THEN transaction_id
    END) AS order_count

FROM {{ ref('stg_events_deduplicated') }}
GROUP BY item_id