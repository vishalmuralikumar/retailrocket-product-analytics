{{ config(materialized='table') }}

WITH observation_bounds AS (
    SELECT
        MIN(event_date) AS observation_start_date,
        MAX(event_date) AS observation_end_date
    FROM {{ ref('fct_events') }}
),

observed_months AS (
    SELECT DISTINCT
        DATE_TRUNC('month', date_day)::DATE AS activity_month
    FROM {{ ref('dim_dates') }}
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM {{ ref('dim_visitors') }}
    GROUP BY cohort_month
),

visitor_month_activity AS (
    SELECT DISTINCT
        visitor_id,
        DATE_TRUNC('month', event_date)::DATE AS activity_month
    FROM {{ ref('fct_events') }}
),

active_counts AS (
    SELECT
        visitors.cohort_month,
        activity.activity_month,
        COUNT(*) AS active_visitor_count

    FROM visitor_month_activity AS activity

    INNER JOIN {{ ref('dim_visitors') }} AS visitors
        ON activity.visitor_id = visitors.visitor_id

    GROUP BY
        visitors.cohort_month,
        activity.activity_month
),

cohort_month_grid AS (
    SELECT
        cohorts.cohort_month,
        months.activity_month,
        cohorts.cohort_size

    FROM cohort_sizes AS cohorts

    CROSS JOIN observed_months AS months

    WHERE months.activity_month >= cohorts.cohort_month
)

SELECT
    grid.cohort_month,
    grid.activity_month,

    DATEDIFF(
        'month',
        grid.cohort_month,
        grid.activity_month
    ) AS months_since_first_seen,

    grid.cohort_size,
    COALESCE(activity.active_visitor_count, 0) AS active_visitor_count,

    COALESCE(activity.active_visitor_count, 0) * 1.0
        / NULLIF(grid.cohort_size, 0) AS retention_rate,

    grid.cohort_month >= bounds.observation_start_date
        AND LAST_DAY(grid.cohort_month) < bounds.observation_end_date
        AS is_cohort_month_fully_observed,

    grid.activity_month >= bounds.observation_start_date
        AND LAST_DAY(grid.activity_month) < bounds.observation_end_date
        AS is_activity_month_fully_observed

FROM cohort_month_grid AS grid

LEFT JOIN active_counts AS activity
    ON grid.cohort_month = activity.cohort_month
    AND grid.activity_month = activity.activity_month

CROSS JOIN observation_bounds AS bounds