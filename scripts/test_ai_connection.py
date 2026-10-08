import os
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def required_env(name):
    value = os.getenv(name)
    if not value:
        raise ValueError(f"Missing environment variable: {name}")
    return value


def main():
    load_dotenv(PROJECT_ROOT / ".env")

    key_path = Path(required_env("AI_SNOWFLAKE_PRIVATE_KEY_PATH"))
    if not key_path.is_absolute():
        key_path = PROJECT_ROOT / key_path

    if not key_path.is_file():
        raise FileNotFoundError(f"Private key not found: {key_path}")

    with snowflake.connector.connect(
        account=required_env("AI_SNOWFLAKE_ACCOUNT"),
        user=required_env("AI_SNOWFLAKE_USER"),
        role=required_env("AI_SNOWFLAKE_ROLE"),
        warehouse=required_env("AI_SNOWFLAKE_WAREHOUSE"),
        database=required_env("AI_SNOWFLAKE_DATABASE"),
        schema=required_env("AI_SNOWFLAKE_SCHEMA"),
        authenticator="SNOWFLAKE_JWT",
        private_key_file=str(key_path),
        session_parameters={
            "QUERY_TAG": "retailrocket_ai_connection_test",
            "STATEMENT_TIMEOUT_IN_SECONDS": 60,
        },
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("USE SECONDARY ROLES NONE")

            cursor.execute("""
                SELECT
                    CURRENT_USER(),
                    CURRENT_ROLE(),
                    CURRENT_DATABASE(),
                    CURRENT_SCHEMA(),
                    CURRENT_WAREHOUSE()
            """)
            print("Connection successful!")
            print(cursor.fetchone())

            cursor.execute("""
                SELECT *
                FROM SEMANTIC_VIEW(
                    RETAILROCKET.ANALYTICS.SV_SESSION_ANALYTICS
                    METRICS
                        sessions.total_sessions,
                        sessions.purchasing_sessions,
                        sessions.session_purchase_rate
                )
            """)
            print("\nSession analytics:")
            print(cursor.fetchone())


if __name__ == "__main__":
    main()