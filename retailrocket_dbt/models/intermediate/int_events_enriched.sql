{{ config(materialized='table') }}

SELECT
    events.*,
    TRY_TO_NUMBER(category.property_value) AS category_id,
    CASE availability.property_value
        WHEN '1' THEN TRUE
        WHEN '0' THEN FALSE
        ELSE NULL
    END AS is_available,
    category.valid_from_utc AS category_recorded_at_utc,
    availability.valid_from_utc AS availability_recorded_at_utc

FROM {{ ref('int_events_sessionized') }} AS events

LEFT JOIN {{ ref('int_product_property_history') }} AS category
    ON events.item_id = category.item_id
    AND category.property = 'categoryid'
    AND events.event_time_utc >= category.valid_from_utc
    AND (
        events.event_time_utc < category.valid_to_utc
        OR category.valid_to_utc IS NULL
    )

LEFT JOIN {{ ref('int_product_property_history') }} AS availability
    ON events.item_id = availability.item_id
    AND availability.property = 'available'
    AND events.event_time_utc >= availability.valid_from_utc
    AND (
        events.event_time_utc < availability.valid_to_utc
        OR availability.valid_to_utc IS NULL
    )