import os
import re
from pathlib import Path

import pandas as pd
import snowflake.connector
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]

METRICS = {
    "total_sessions",
    "purchasing_sessions",
    "session_purchase_rate",
    "active_visitors",
}

DIMENSIONS = {
    "session_date",
    "session_month",
}


def validate_sql(sql):
    """
    Accept a restricted SELECT from our session semantic view.
    Reject other SQL rather than executing it.
    """
    # Remove line comments, including Cortex's request-ID comment.
    clean_sql = re.sub(r"--[^\r\n]*", "", sql).strip()
    clean_sql = clean_sql.removesuffix(";").strip()

    pattern = (
        r"SELECT\s+\*\s+FROM\s+SEMANTIC_VIEW\s*\(\s*"
        r"RETAILROCKET\.ANALYTICS\.SV_SESSION_ANALYTICS\s+"
        r"(?:DIMENSIONS\s+(?P<dimensions>[\w.,\s]+?)\s+)?"
        r"METRICS\s+(?P<metrics>[\w.,\s]+?)\s*\)"
    )

    match = re.fullmatch(pattern, clean_sql, flags=re.IGNORECASE)

    if not match:
        raise ValueError(
            "This query is outside the supported SQL format. "
            "Try an overall metric or a metric grouped by month."
        )

    for group_name, allowed in [
        ("metrics", METRICS),
        ("dimensions", DIMENSIONS),
    ]:
        values = match.group(group_name)

        if values is None:
            continue

        for value in values.split(","):
            identifier = value.strip().lower()
            parts = identifier.split(".")

            if len(parts) == 2 and parts[0] == "sessions":
                identifier = parts[1]
            elif len(parts) != 1:
                raise ValueError("Unsupported metric or dimension.")

            if identifier not in allowed:
                raise ValueError(f"Unsupported identifier: {identifier}")

    return clean_sql


def execute_query(sql):
    load_dotenv(PROJECT_ROOT / ".env")
    validated_sql = validate_sql(sql)

    key_path = Path(os.environ["AI_SNOWFLAKE_PRIVATE_KEY_PATH"])
    if not key_path.is_absolute():
        key_path = PROJECT_ROOT / key_path

    with snowflake.connector.connect(
        account=os.environ["AI_SNOWFLAKE_ACCOUNT"],
        user=os.environ["AI_SNOWFLAKE_USER"],
        role=os.environ["AI_SNOWFLAKE_ROLE"],
        warehouse=os.environ["AI_SNOWFLAKE_WAREHOUSE"],
        database=os.environ["AI_SNOWFLAKE_DATABASE"],
        schema=os.environ["AI_SNOWFLAKE_SCHEMA"],
        authenticator="SNOWFLAKE_JWT",
        private_key_file=str(key_path),
        session_parameters={
            "QUERY_TAG": "retailrocket_ai_assistant",
            "STATEMENT_TIMEOUT_IN_SECONDS": 60,
        },
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("USE SECONDARY ROLES NONE")
            cursor.execute(validated_sql + " LIMIT 501")

            rows = cursor.fetchmany(501)
            columns = [column[0] for column in cursor.description]
            query_id = cursor.sfqid

    truncated = len(rows) > 500
    dataframe = pd.DataFrame(rows[:500], columns=columns)

    return dataframe, query_id, truncated