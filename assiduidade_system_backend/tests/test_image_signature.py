import base64

import pytest
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from app.security.image_signature import verify_image_signature


def _generate_signed_message(message: str):
    private_key = Ed25519PrivateKey.generate()
    public_key = private_key.public_key()
    signature = private_key.sign(message.encode("utf-8"))
    return (
        base64.b64encode(public_key.public_bytes_raw()).decode("ascii"),
        base64.b64encode(signature).decode("ascii"),
    )


def test_verify_valid_signature():
    message = "fake-image-base64"
    public_key_b64, signature_b64 = _generate_signed_message(message)
    assert verify_image_signature(public_key_b64, message, signature_b64) is True


def test_verify_invalid_signature():
    message = "fake-image-base64"
    public_key_b64, _ = _generate_signed_message(message)
    assert verify_image_signature(public_key_b64, message, "dGVzdA==") is False


def test_verify_missing_params():
    assert verify_image_signature(None, "message", "sig") is False
    assert verify_image_signature("key", None, "sig") is False
    assert verify_image_signature("key", "message", None) is False
