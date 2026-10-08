WITH retention AS (
    SELECT *
    FROM {{ ref('mart_monthly_visitor_retention') }}
),

invalid_rows AS (
    SELECT cohort_month, activity_month
    FROM retention
    WHERE months_since_first_seen < 0
       OR cohort_size <= 0
       OR active_visitor_count < 0
       OR active_visitor_count > cohort_size
       OR retention_rate < 0
       OR retention_rate > 1
       OR (
           months_since_first_seen = 0
           AND active_visitor_count <> cohort_size
       )
),

duplicate_rows AS (
    SELECT cohort_month, activity_month
    FROM retention
    GROUP BY cohort_month, activity_month
    HAVING COUNT(*) > 1
)

SELECT * FROM invalid_rows
UNION ALL
SELECT * FROM duplicate_rows