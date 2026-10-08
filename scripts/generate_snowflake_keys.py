from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa


def main():
    project_root = Path(__file__).resolve().parents[1]
    secrets_dir = project_root / "secrets"
    secrets_dir.mkdir(exist_ok=True)

    private_path = secrets_dir / "snowflake_ai_private_key.p8"
    public_path = secrets_dir / "snowflake_ai_public_key.pub"

    if private_path.exists() or public_path.exists():
        raise FileExistsError(
            "Keys already exist. Existing keys will not be overwritten."
        )

    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    private_path.write_bytes(
        private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
    )

    public_path.write_bytes(
        private_key.public_key().public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo,
        )
    )

    print("Snowflake key pair created.")
    print(f"Private key: {private_path}")
    print(f"Public key: {public_path}")


if __name__ == "__main__":
    main()