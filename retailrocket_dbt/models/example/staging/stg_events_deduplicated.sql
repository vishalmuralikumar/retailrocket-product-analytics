{{ config(materialized='view') }}

SELECT
    timestamp_ms,
    event_time_utc,
    visitor_id,
    event_type,
    item_id,
    transaction_id,
    source_file,
    source_row_number,
    ingested_at
FROM {{ ref('stg_events') }}

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY
        timestamp_ms,
        visitor_id,
        event_type,
        item_id,
        transaction_id
    ORDER BY
        source_file,
        source_row_number,
        ingested_at
) = 1