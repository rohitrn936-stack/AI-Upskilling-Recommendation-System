import os
from cryptography.fernet import Fernet
from typing import Optional


def get_fernet() -> Optional[Fernet]:
    """Get a Fernet instance for encrypting/decrypting API keys.

    The encryption key is supplied via the CRYPTO_KEY environment variable,
    which should be a valid Fernet key (base64-encoded 32-byte key).
    If not set, encryption will be unavailable and API keys will be stored
    in plaintext (not recommended for production).

    Returns:
        Fernet instance or None if no key is configured.
    """
    key = os.environ.get("CRYPTO_KEY")
    if not key:
        return None
    try:
        return Fernet(key.encode())
    except Exception:
        return None


def encrypt_api_key(api_key: str) -> Optional[str]:
    """Encrypt an API key using Fernet encryption.

    Args:
        api_key: The plaintext API key to encrypt.

    Returns:
        Encrypted token as a string, or None if encryption is unavailable.
    """
    fernet = get_fernet()
    if fernet is None:
        return None
    return fernet.encrypt(api_key.encode()).decode()


def decrypt_api_key(encrypted_key: str) -> Optional[str]:
    """Decrypt an encrypted API key using Fernet encryption.

    Args:
        encrypted_key: The encrypted API key token.

    Returns:
        The plaintext API key, or None if decryption fails or encryption
        is unavailable.
    """
    fernet = get_fernet()
    if fernet is None:
        return None
    try:
        return fernet.decrypt(encrypted_key.encode()).decode()
    except Exception:
        return None


def is_encryption_available() -> bool:
    """Check if encryption is properly configured."""
    return get_fernet() is not None