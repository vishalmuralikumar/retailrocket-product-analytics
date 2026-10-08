SELECT session_id, item_id
FROM {{ ref('int_session_product_funnel') }}
WHERE
    (
        first_cart_after_view_at_utc IS NOT NULL
        AND first_cart_after_view_at_utc <= first_view_at_utc
    )
    OR
    (
        first_purchase_after_cart_at_utc IS NOT NULL
        AND (
            first_cart_after_view_at_utc IS NULL
            OR first_purchase_after_cart_at_utc
               <= first_cart_after_view_at_utc
        )
    )
    OR reached_cart <>
       (first_cart_after_view_at_utc IS NOT NULL)
    OR reached_purchase <>
       (first_purchase_after_cart_at_utc IS NOT NULL)

UNION ALL

SELECT session_id, item_id
FROM {{ ref('int_session_product_funnel') }}
GROUP BY session_id, item_id
HAVING COUNT(*) > 1