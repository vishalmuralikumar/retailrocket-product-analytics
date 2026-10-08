{{ config(materialized='view') }}

SELECT
    timestamp_ms,
    TO_TIMESTAMP_NTZ(timestamp_ms, 3) AS property_time_utc,
    item_id,
    property,
    property_value,
    source_file,
    source_row_number,
    ingested_at
FROM {{ source('retailrocket', 'item_properties') }}