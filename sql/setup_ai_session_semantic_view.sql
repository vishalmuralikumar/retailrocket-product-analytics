USE ROLE SYSADMIN;
USE WAREHOUSE RETAILROCKET_WH;

CREATE OR REPLACE SEMANTIC VIEW
    RETAILROCKET.ANALYTICS.SV_SESSION_ANALYTICS
TABLES (
    sessions AS RETAILROCKET.ANALYTICS.FCT_SESSIONS
)
DIMENSIONS (
    sessions.session_date AS sessions.SESSION_DATE,
    sessions.session_month AS
        DATE_TRUNC('MONTH', sessions.SESSION_DATE)
)
METRICS (
    sessions.total_sessions AS COUNT(*),

    sessions.purchasing_sessions AS
        SUM(IFF(sessions.HAS_PURCHASE, 1, 0)),

    sessions.session_purchase_rate AS
        SUM(IFF(sessions.HAS_PURCHASE, 1, 0))
        / NULLIF(COUNT(*), 0),

    sessions.active_visitors AS
        COUNT(DISTINCT sessions.VISITOR_ID)
);

SELECT *
FROM SEMANTIC_VIEW(
    RETAILROCKET.ANALYTICS.SV_SESSION_ANALYTICS
    METRICS
        sessions.total_sessions,
        sessions.purchasing_sessions,
        sessions.session_purchase_rate,
        sessions.active_visitors
);