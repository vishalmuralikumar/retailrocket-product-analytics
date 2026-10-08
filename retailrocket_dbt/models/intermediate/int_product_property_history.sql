{{ config(materialized='table') }}

WITH distinct_records AS (
    SELECT DISTINCT
        item_id,
        property,
        property_value,
        property_time_utc
    FROM {{ ref('stg_item_properties') }}
    WHERE property IN ('categoryid', 'available')
),

previous_values AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY item_id, property
            ORDER BY property_time_utc
        ) AS record_number,

        LAG(property_value) OVER (
            PARTITION BY item_id, property
            ORDER BY property_time_utc
        ) AS previous_property_value
    FROM distinct_records
),

changes_only AS (
    SELECT
        item_id,
        property,
        property_value,
        property_time_utc AS valid_from_utc
    FROM previous_values
    WHERE record_number = 1
       OR property_value IS DISTINCT FROM previous_property_value
),

validity_intervals AS (
    SELECT
        *,
        LEAD(valid_from_utc) OVER (
            PARTITION BY item_id, property
            ORDER BY valid_from_utc
        ) AS valid_to_utc
    FROM changes_only
)

SELECT
    item_id,
    property,
    property_value,
    valid_from_utc,
    valid_to_utc,
    valid_to_utc IS NULL AS is_latest_record
FROM validity_intervals