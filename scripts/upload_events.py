from getpass import getpass
from pathlib import Path

import snowflake.connector
from dotenv import dotenv_values

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def main():
    files = list((PROJECT_ROOT / "data" / "raw").rglob("events.csv"))

    if len(files) != 1:
        raise ValueError(f"Expected one events.csv, found {len(files)}")

    settings = dotenv_values(PROJECT_ROOT / ".env")
    config = {}

    for name in ["ACCOUNT", "USER", "ROLE", "WAREHOUSE", "DATABASE", "SCHEMA"]:
        key = f"SNOWFLAKE_{name}"
        value = (settings.get(key) or "").strip()

        if not value:
            raise ValueError(f"Missing configuration: {key}")

        config[name.lower()] = value

    connection = snowflake.connector.connect(
        **config,
        password=getpass("Enter your Snowflake password: "),
        authenticator="username_password_mfa",
        login_timeout=120,
    )

    try:
        with connection.cursor() as cursor:
            local_path = files[0].resolve().as_posix()
            file_uri = ("file://" + local_path).replace("'", "''")

            print("Uploading events.csv...")

            cursor.execute(
                f"PUT '{file_uri}' "
                "@RETAILROCKET.RAW.RETAILROCKET_STAGE/events/ "
                "AUTO_COMPRESS=TRUE OVERWRITE=FALSE"
            )

            columns = [column[0] for column in cursor.description]

            for row in cursor.fetchall():
                print(dict(zip(columns, row)))

            print("\nFILES IN STAGE")

            cursor.execute(
                "LIST @RETAILROCKET.RAW.RETAILROCKET_STAGE/events/"
            )

            for row in cursor.fetchall():
                print(row)

    finally:
        connection.close()


if __name__ == "__main__":
    main()