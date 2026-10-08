{{ config(materialized='table') }}

SELECT
    source_file || ':' || TO_VARCHAR(source_row_number) AS event_id,
    timestamp_ms,
    event_time_utc,
    TO_DATE(event_time_utc) AS event_date,
    visitor_id,
    session_id,
    item_id,
    event_type,
    transaction_id AS order_id,
    category_id,
    is_available,
    category_id IS NOT NULL AS has_known_category,
    is_available IS NOT NULL AS has_known_availability,
    source_file,
    source_row_number,
    ingested_at
FROM {{ ref('int_events_enriched') }}