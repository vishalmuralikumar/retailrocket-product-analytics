{{ config(materialized='table') }}

WITH product_ids AS (
    SELECT item_id
    FROM {{ ref('stg_item_properties') }}

    UNION

    SELECT item_id
    FROM {{ ref('int_product_activity') }}
)

SELECT
    products.item_id,
    'Product ' || TO_VARCHAR(products.item_id) AS product_label,
    activity.first_seen_at_utc AS first_observed_event_at_utc,
    activity.last_seen_at_utc AS last_observed_event_at_utc,
    activity.item_id IS NOT NULL AS has_observed_events
FROM product_ids AS products
LEFT JOIN {{ ref('int_product_activity') }} AS activity
    ON products.item_id = activity.item_id