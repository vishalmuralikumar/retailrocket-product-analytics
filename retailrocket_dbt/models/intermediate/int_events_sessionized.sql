{{ config(materialized='table') }}

WITH previous_event AS (
    SELECT
        *,
        LAG(event_time_utc) OVER (
            PARTITION BY visitor_id
            ORDER BY timestamp_ms, source_file, source_row_number
        ) AS previous_event_time_utc
    FROM {{ ref('stg_events_deduplicated') }}
),

session_boundaries AS (
    SELECT
        *,
        CASE
            WHEN previous_event_time_utc IS NULL THEN 1
            WHEN timestamp_ms
                 - DATE_PART('epoch_millisecond', previous_event_time_utc)
                 >= 1800000 THEN 1
            ELSE 0
        END AS is_new_session
    FROM previous_event
),

session_numbers AS (
    SELECT
        *,
        SUM(is_new_session) OVER (
            PARTITION BY visitor_id
            ORDER BY timestamp_ms, source_file, source_row_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_number
    FROM session_boundaries
)

SELECT
    timestamp_ms,
    event_time_utc,
    visitor_id,
    event_type,
    item_id,
    transaction_id,
    source_file,
    source_row_number,
    ingested_at,
    session_number,
    TO_VARCHAR(visitor_id)
        || '-'
        || TO_VARCHAR(session_number) AS session_id
FROM session_numbers