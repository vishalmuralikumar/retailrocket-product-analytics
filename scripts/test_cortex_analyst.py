import base64
import hashlib
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
import requests
from cryptography.hazmat.primitives import serialization
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def required_env(name):
    value = os.getenv(name)

    if not value:
        raise ValueError(f"Missing environment variable: {name}")

    return value


def ask_analyst(question):
    """Send one question to Cortex Analyst and return its response."""
    load_dotenv(PROJECT_ROOT / ".env")

    account = required_env("AI_SNOWFLAKE_ACCOUNT").upper()
    user = required_env("AI_SNOWFLAKE_USER").upper()
    semantic_view = required_env("AI_SNOWFLAKE_SEMANTIC_VIEW")

    key_path = Path(required_env("AI_SNOWFLAKE_PRIVATE_KEY_PATH"))

    if not key_path.is_absolute():
        key_path = PROJECT_ROOT / key_path

    if not key_path.is_file():
        raise FileNotFoundError(f"Private key not found: {key_path}")

    private_key = serialization.load_pem_private_key(
        key_path.read_bytes(),
        password=None,
    )

    public_key_der = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    fingerprint = "SHA256:" + base64.b64encode(
        hashlib.sha256(public_key_der).digest()
    ).decode("ascii")

    identity = f"{account}.{user}"
    now = datetime.now(timezone.utc)

    token = jwt.encode(
        {
            "iss": f"{identity}.{fingerprint}",
            "sub": identity,
            "iat": now,
            "exp": now + timedelta(minutes=10),
        },
        private_key,
        algorithm="RS256",
    )

    response = requests.post(
        f"https://{account.lower()}.snowflakecomputing.com"
        "/api/v2/cortex/analyst/message",
        headers={
            "Authorization": f"Bearer {token}",
            "X-Snowflake-Authorization-Token-Type": "KEYPAIR_JWT",
            "Content-Type": "application/json",
        },
        json={
            "semantic_view": semantic_view,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": question,
                        }
                    ],
                }
            ],
        },
        timeout=(10, 120),
    )

    if not response.ok:
        raise RuntimeError(
            f"Cortex Analyst HTTP {response.status_code}: "
            f"{response.text[:2000]}"
        )

    return response.json()


def main():
    result = ask_analyst("What is the overall session purchase rate?")

    print("Cortex Analyst API successful!")
    print("Request ID:", result.get("request_id"))

    for content in result.get("message", {}).get("content", []):
        content_type = content.get("type")

        if content_type == "text":
            print("\nExplanation:")
            print(content["text"])

        elif content_type == "sql":
            print("\nGenerated SQL:")
            print(content["statement"])

        elif content_type == "suggestions":
            print("\nSuggested questions:")

            for suggestion in content["suggestions"]:
                print("-", suggestion)


if __name__ == "__main__":
    main()