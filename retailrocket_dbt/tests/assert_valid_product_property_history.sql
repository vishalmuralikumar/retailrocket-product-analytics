WITH checked AS (
    SELECT
        *,
        LEAD(valid_from_utc) OVER (
            PARTITION BY item_id, property
            ORDER BY valid_from_utc
        ) AS next_valid_from_utc
    FROM {{ ref('int_product_property_history') }}
)

SELECT item_id, property, valid_from_utc
FROM checked
WHERE
    valid_to_utc <= valid_from_utc
    OR valid_to_utc IS DISTINCT FROM next_valid_from_utc
    OR is_latest_record <> (valid_to_utc IS NULL)
    OR (
        property = 'available'
        AND property_value NOT IN ('0', '1')
    )

UNION ALL

SELECT item_id, property, valid_from_utc
FROM {{ ref('int_product_property_history') }}
GROUP BY item_id, property, valid_from_utc
HAVING COUNT(*) > 1

UNION ALL

SELECT item_id, property, MIN(valid_from_utc)
FROM {{ ref('int_product_property_history') }}
GROUP BY item_id, property
HAVING COUNT_IF(is_latest_record) <> 1