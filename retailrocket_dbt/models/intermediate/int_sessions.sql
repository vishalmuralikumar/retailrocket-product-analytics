{{ config(materialized='view') }}

SELECT
    session_id,
    visitor_id,
    session_number,

    MIN(event_time_utc) AS session_start_at_utc,
    MAX(event_time_utc) AS session_end_at_utc,

    DATEDIFF(
        'millisecond',
        MIN(event_time_utc),
        MAX(event_time_utc)
    ) / 1000.0 AS observed_duration_seconds,

    COUNT(*) AS total_event_count,
    COUNT_IF(event_type = 'view') AS view_event_count,
    COUNT_IF(event_type = 'addtocart') AS add_to_cart_event_count,
    COUNT_IF(event_type = 'transaction') AS purchase_event_count,

    COUNT(DISTINCT item_id) AS distinct_product_count,

    COUNT(DISTINCT CASE
        WHEN event_type = 'transaction' THEN transaction_id
    END) AS order_count,

    COUNT_IF(event_type = 'transaction') > 0 AS has_purchase

FROM {{ ref('int_events_sessionized') }}
GROUP BY session_id, visitor_id, session_number