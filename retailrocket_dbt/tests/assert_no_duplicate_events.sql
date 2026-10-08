SELECT
    timestamp_ms,
    visitor_id,
    event_type,
    item_id,
    transaction_id,
    COUNT(*) AS occurrences
FROM {{ ref('stg_events_deduplicated') }}
GROUP BY
    timestamp_ms,
    visitor_id,
    event_type,
    item_id,
    transaction_id
HAVING COUNT(*) > 1