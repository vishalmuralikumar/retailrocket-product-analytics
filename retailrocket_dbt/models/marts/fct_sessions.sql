{{ config(materialized='table', enabled=true) }}

SELECT
    session_id,
    visitor_id,
    session_number,
    session_start_at_utc,
    session_end_at_utc,
    TO_DATE(session_start_at_utc) AS session_date,
    observed_duration_seconds,
    total_event_count,
    view_event_count,
    add_to_cart_event_count,
    purchase_event_count,
    distinct_product_count,
    order_count,
    has_purchase
FROM {{ ref('int_sessions') }}