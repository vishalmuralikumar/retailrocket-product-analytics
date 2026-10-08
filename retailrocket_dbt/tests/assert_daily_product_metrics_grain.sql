SELECT
    event_date,
    item_id,
    COUNT(*) AS row_count
FROM {{ ref('mart_daily_product_metrics') }}
GROUP BY event_date, item_id
HAVING COUNT(*) > 1