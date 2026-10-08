from getpass import getpass
from pathlib import Path

import snowflake.connector
from dotenv import dotenv_values

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def main():
    env_path = PROJECT_ROOT / ".env"

    if not env_path.is_file():
        raise FileNotFoundError(f"Configuration file not found: {env_path}")

    settings = dotenv_values(env_path)
    config = {}

    for name in [
        "ACCOUNT",
        "USER",
        "ROLE",
        "WAREHOUSE",
        "DATABASE",
        "SCHEMA",
    ]:
        key = f"SNOWFLAKE_{name}"
        value = (settings.get(key) or "").strip()

        if not value:
            raise ValueError(f"{key} is missing or empty in .env")

        config[name.lower()] = value

    print("Configuration loaded. Required values are present.")

    connection = snowflake.connector.connect(
        **config,
        password=getpass("Enter your Snowflake password: "),
        authenticator="username_password_mfa",
        login_timeout=120,
    )

    try:
        with connection.cursor() as cursor:
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
    finally:
        connection.close()


if __name__ == "__main__":
    main()