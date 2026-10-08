{{ config(materialized='table') }}

WITH first_views AS (
    SELECT
        session_id,
        visitor_id,
        item_id,
        MIN(event_time_utc) AS first_view_at_utc
    FROM {{ ref('int_events_sessionized') }}
    WHERE event_type = 'view'
    GROUP BY session_id, visitor_id, item_id
),

first_carts_after_view AS (
    SELECT
        views.session_id,
        views.visitor_id,
        views.item_id,
        views.first_view_at_utc,
        MIN(events.event_time_utc) AS first_cart_after_view_at_utc
    FROM first_views AS views
    LEFT JOIN {{ ref('int_events_sessionized') }} AS events
        ON views.session_id = events.session_id
        AND views.item_id = events.item_id
        AND events.event_type = 'addtocart'
        AND events.event_time_utc > views.first_view_at_utc
    GROUP BY
        views.session_id,
        views.visitor_id,
        views.item_id,
        views.first_view_at_utc
),

first_purchases_after_cart AS (
    SELECT
        carts.session_id,
        carts.visitor_id,
        carts.item_id,
        carts.first_view_at_utc,
        carts.first_cart_after_view_at_utc,
        MIN(events.event_time_utc) AS first_purchase_after_cart_at_utc
    FROM first_carts_after_view AS carts
    LEFT JOIN {{ ref('int_events_sessionized') }} AS events
        ON carts.session_id = events.session_id
        AND carts.item_id = events.item_id
        AND events.event_type = 'transaction'
        AND events.event_time_utc > carts.first_cart_after_view_at_utc
    GROUP BY
        carts.session_id,
        carts.visitor_id,
        carts.item_id,
        carts.first_view_at_utc,
        carts.first_cart_after_view_at_utc
)

SELECT
    *,
    first_cart_after_view_at_utc IS NOT NULL AS reached_cart,
    first_purchase_after_cart_at_utc IS NOT NULL AS reached_purchase
FROM first_purchases_after_cart