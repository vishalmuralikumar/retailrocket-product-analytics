{{ config(materialized='table') }}

SELECT
    order_id,
    visitor_id,
    order_time_utc,
    TO_DATE(order_time_utc) AS order_date,
    last_purchase_event_time_utc,
    purchase_event_count,
    distinct_product_count
FROM {{ ref('int_orders') }}