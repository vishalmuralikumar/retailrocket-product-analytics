{{ config(materialized='view') }}

SELECT
    timestamp_ms,
    TO_TIMESTAMP_NTZ(timestamp_ms, 3) AS event_time_utc,
    visitor_id,
    event_type,
    item_id,
    transaction_id,
    source_file,
    source_row_number,
    ingested_at
FROM {{ source('retailrocket', 'events') }}