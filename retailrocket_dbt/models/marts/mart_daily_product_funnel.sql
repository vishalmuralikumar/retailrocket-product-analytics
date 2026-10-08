{{ config(materialized='table') }}

WITH daily_funnel AS (
    SELECT
        sessions.session_date AS funnel_date,
        funnel.item_id,

        COUNT(*) AS viewed_session_product_count,

        SUM(
            CASE WHEN funnel.reached_cart THEN 1 ELSE 0 END
        ) AS cart_session_product_count,

        SUM(
            CASE WHEN funnel.reached_purchase THEN 1 ELSE 0 END
        ) AS purchased_session_product_count

    FROM {{ ref('int_session_product_funnel') }} AS funnel

    INNER JOIN {{ ref('fct_sessions') }} AS sessions
        ON funnel.session_id = sessions.session_id

    GROUP BY
        sessions.session_date,
        funnel.item_id
)

SELECT
    funnel_date,
    item_id,
    viewed_session_product_count,
    cart_session_product_count,
    purchased_session_product_count,

    cart_session_product_count * 1.0
        / NULLIF(viewed_session_product_count, 0)
        AS view_to_cart_rate,

    purchased_session_product_count * 1.0
        / NULLIF(cart_session_product_count, 0)
        AS cart_to_purchase_rate,

    purchased_session_product_count * 1.0
        / NULLIF(viewed_session_product_count, 0)
        AS view_to_purchase_rate

FROM daily_funnel