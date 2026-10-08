SELECT *
FROM {{ ref('int_orders') }}
WHERE purchase_event_count < 1
   OR distinct_product_count < 1
   OR distinct_product_count > purchase_event_count
   OR last_purchase_event_time_utc < order_time_utc