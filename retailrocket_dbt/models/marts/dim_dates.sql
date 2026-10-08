{{ config(materialized='table') }}

WITH bounds AS (
    SELECT
        MIN(event_date) AS start_date,
        MAX(event_date) AS end_date
    FROM {{ ref('fct_events') }}
),

date_series AS (
    SELECT
        DATEADD(
            'day',
            offsets.value::INTEGER,
            bounds.start_date
        )::DATE AS date_day
    FROM bounds,
    LATERAL FLATTEN(
        INPUT => ARRAY_GENERATE_RANGE(
            0,
            DATEDIFF('day', bounds.start_date, bounds.end_date) + 1
        )
    ) AS offsets
)

SELECT
    date_day,
    YEAR(date_day) AS calendar_year,
    QUARTER(date_day) AS calendar_quarter,
    MONTH(date_day) AS month_number,
    TO_CHAR(date_day, 'YYYY-MM') AS year_month,
    DAY(date_day) AS day_of_month,
    DAYOFWEEKISO(date_day) AS iso_day_of_week,
    DAYNAME(date_day) AS day_name,
    DAYOFWEEKISO(date_day) IN (6, 7) AS is_weekend
FROM date_series