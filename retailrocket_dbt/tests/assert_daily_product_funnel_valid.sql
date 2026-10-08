WITH metrics AS (
    SELECT *
    FROM {{ ref('mart_daily_product_funnel') }}
),

invalid_counts AS (
    SELECT funnel_date, item_id
    FROM metrics
    WHERE viewed_session_product_count <= 0
       OR cart_session_product_count < 0
       OR purchased_session_product_count < 0
       OR cart_session_product_count > viewed_session_product_count
       OR purchased_session_product_count > cart_session_product_count
),

duplicate_rows AS (
    SELECT funnel_date, item_id
    FROM metrics
    GROUP BY funnel_date, item_id
    HAVING COUNT(*) > 1
)

SELECT * FROM invalid_counts
UNION ALL
SELECT * FROM duplicate_rows