from getpass import getpass
from pathlib import Path

import snowflake.connector
from dotenv import dotenv_values

PROJECT_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_DIR / "data" / "raw"

FILES_TO_UPLOAD = {
    "item_properties_part1.csv": "item_properties",
    "item_properties_part2.csv": "item_properties",
    "category_tree.csv": "categories",
}


def main():
    # Validate all local files before connecting.
    upload_files = []

    for filename, stage_folder in FILES_TO_UPLOAD.items():
        matches = list(RAW_DIR.rglob(filename))

        if len(matches) != 1:
            raise FileNotFoundError(
                f"Expected exactly one {filename} in {RAW_DIR}; "
                f"found {len(matches)}"
            )

        upload_files.append((matches[0], stage_folder))

    settings = dotenv_values(PROJECT_DIR / ".env")

    required_settings = {
        "account": "SNOWFLAKE_ACCOUNT",
        "user": "SNOWFLAKE_USER",
        "role": "SNOWFLAKE_ROLE",
        "warehouse": "SNOWFLAKE_WAREHOUSE",
        "database": "SNOWFLAKE_DATABASE",
        "schema": "SNOWFLAKE_SCHEMA",
    }

    config = {}

    for parameter, env_name in required_settings.items():
        value = settings.get(env_name)

        if not value or not value.strip():
            raise ValueError(f"{env_name} is missing or empty in .env")

        config[parameter] = value.strip()

    connection = snowflake.connector.connect(
        **config,
        password=getpass("Snowflake password: "),
        authenticator="username_password_mfa",
        login_timeout=120,
    )

    try:
        with connection.cursor() as cursor:
            for path, stage_folder in upload_files:
                file_uri = (
                    "file://" + path.resolve().as_posix()
                ).replace("'", "''")

                print(f"\nUPLOADING: {path.name}")

                cursor.execute(
                    f"PUT '{file_uri}' "
                    f"@RETAILROCKET.RAW.RETAILROCKET_STAGE/{stage_folder}/ "
                    "AUTO_COMPRESS = TRUE "
                    "OVERWRITE = FALSE"
                )

                columns = [
                    column[0] for column in cursor.description
                ]

                for row in cursor.fetchall():
                    print(dict(zip(columns, row)))

            print("\nFILES IN STAGE")

            cursor.execute(
                "LIST @RETAILROCKET.RAW.RETAILROCKET_STAGE"
            )

            for row in cursor.fetchall():
                print(row)

    finally:
        connection.close()


if __name__ == "__main__":
    main()