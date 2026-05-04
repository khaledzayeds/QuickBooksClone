#!/usr/bin/env python3
"""
Generate an Ed25519 keypair for LedgerFlow license signing.

Install dependency:
  pip install cryptography

Usage:
  python tools/license_admin/generate_keypair.py

Output:
- Private key: keep secret; use only in admin tool/server.
- Public key: paste into Flutter LicensePublicKeyConfig.ed25519PublicKeyBase64.
"""

from __future__ import annotations

import base64
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def main() -> None:
    private_key = Ed25519PrivateKey.generate()
    private_bytes = private_key.private_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PrivateFormat.Raw,
        encryption_algorithm=serialization.NoEncryption(),
    )
    public_bytes = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )

    print("\n=== LedgerFlow Ed25519 License Keypair ===\n")
    print("PRIVATE KEY BASE64 — KEEP SECRET:")
    print(b64(private_bytes))
    print("\nPUBLIC KEY BASE64 — paste into Flutter LicensePublicKeyConfig:")
    print(b64(public_bytes))
    print("\nWARNING: Never commit the real private key to GitHub. Store it in a password manager or server secret store.\n")


if __name__ == "__main__":
    main()
