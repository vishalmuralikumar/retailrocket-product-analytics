{{ config(materialized='view') }}

WITH visitor_activity AS (
    SELECT
        visitor_id,
        MIN(event_time_utc) AS first_seen_at_utc,
        MAX(event_time_utc) AS last_seen_at_utc,
        COUNT(*) AS total_event_count,
        COUNT_IF(event_type = 'view') AS view_event_count,
        COUNT_IF(event_type = 'addtocart') AS add_to_cart_event_count,
        COUNT_IF(event_type = 'transaction') AS purchase_event_count,
        COUNT(DISTINCT item_id) AS distinct_interacted_product_count
    FROM {{ ref('stg_events_deduplicated') }}
    GROUP BY visitor_id
),

visitor_orders AS (
    SELECT
        visitor_id,
        COUNT(*) AS order_count,
        MIN(order_time_utc) AS first_order_at_utc,
        MAX(order_time_utc) AS last_order_at_utc
    FROM {{ ref('int_orders') }}
    GROUP BY visitor_id
)

SELECT
    activity.visitor_id,
    activity.first_seen_at_utc,
    activity.last_seen_at_utc,
    activity.total_event_count,
    activity.view_event_count,
    activity.add_to_cart_event_count,
    activity.purchase_event_count,
    activity.distinct_interacted_product_count,
    COALESCE(orders.order_count, 0) AS order_count,
    orders.first_order_at_utc,
    orders.last_order_at_utc,
    COALESCE(orders.order_count, 0) > 0 AS is_purchaser
FROM visitor_activity AS activity
LEFT JOIN visitor_orders AS orders
    ON activity.visitor_id = orders.visitor_id