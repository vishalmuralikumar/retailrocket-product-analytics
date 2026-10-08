{{ config(materialized='table') }}

SELECT
    event_date,
    item_id,

    COUNT(*) AS total_event_count,
    COUNT(DISTINCT visitor_id) AS interacting_visitor_count,
    COUNT(DISTINCT session_id) AS session_count,

    SUM(CASE WHEN event_type = 'view'
        THEN 1 ELSE 0 END) AS view_event_count,

    SUM(CASE WHEN event_type = 'addtocart'
        THEN 1 ELSE 0 END) AS add_to_cart_event_count,

    SUM(CASE WHEN event_type = 'transaction'
        THEN 1 ELSE 0 END) AS purchase_event_count,

    COUNT(DISTINCT CASE WHEN event_type = 'view'
        THEN visitor_id END) AS viewing_visitor_count,

    COUNT(DISTINCT CASE WHEN event_type = 'addtocart'
        THEN visitor_id END) AS cart_visitor_count,

    COUNT(DISTINCT CASE WHEN event_type = 'transaction'
        THEN visitor_id END) AS purchasing_visitor_count,

    COUNT(DISTINCT CASE WHEN event_type = 'transaction'
        THEN order_id END) AS order_count

FROM {{ ref('fct_events') }}
GROUP BY event_date, item_id