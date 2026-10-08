WITH source_events AS (
    SELECT
        source_file,
        source_row_number,
        COUNT(*) AS source_count
    FROM {{ ref('int_events_sessionized') }}
    GROUP BY source_file, source_row_number
),

enriched_events AS (
    SELECT
        source_file,
        source_row_number,
        COUNT(*) AS enriched_count
    FROM {{ ref('int_events_enriched') }}
    GROUP BY source_file, source_row_number
)

SELECT
    COALESCE(source.source_file, enriched.source_file) AS source_file,
    COALESCE(
        source.source_row_number,
        enriched.source_row_number
    ) AS source_row_number
FROM source_events AS source
FULL OUTER JOIN enriched_events AS enriched
    ON source.source_file = enriched.source_file
    AND source.source_row_number = enriched.source_row_number
WHERE source.source_count IS DISTINCT FROM enriched.enriched_count
   OR source.source_count <> 1
   OR enriched.enriched_count <> 1

UNION ALL

SELECT source_file, source_row_number
FROM {{ ref('int_events_enriched') }}
WHERE category_recorded_at_utc > event_time_utc
   OR availability_recorded_at_utc > event_time_utc