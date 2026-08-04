"""Testes unitários do signer HMAC Nexora."""

import hashlib
import hmac
import json

import pytest

from nexora_sdk.signer import canonical_string, serialize_body, sign_request


def test_sign_request_produces_all_headers():
    headers = sign_request(
        access_key_id="nexora_ak_test",
        secret_access_key="nexora_sk_test",
        method="POST",
        path="/api/biometric/verify",
        payload={"user_id": "usr_123", "image_base64": "abc"},
    )

    assert headers["X-Nexora-Access-Key"] == "nexora_ak_test"
    assert "X-Nexora-Timestamp" in headers
    assert "X-Nexora-Nonce" in headers
    assert "X-Nexora-Content-SHA256" in headers
    assert "X-Nexora-Signature" in headers
    assert headers["X-Nexora-Auth-Version"] == "NEXORA-HMAC-SHA256-V1"


def test_sign_request_signature_is_valid():
    secret = "nexora_sk_test"
    payload = {"user_id": "usr_123", "image_base64": "abc"}
    headers = sign_request(
        access_key_id="nexora_ak_test",
        secret_access_key=secret,
        method="POST",
        path="/api/biometric/verify",
        payload=payload,
    )

    body = serialize_body(payload)
    expected_body_hash = hashlib.sha256(body).hexdigest()
    assert headers["X-Nexora-Content-SHA256"] == expected_body_hash

    canonical = canonical_string(
        method="POST",
        path="/api/biometric/verify",
        query="",
        timestamp=headers["X-Nexora-Timestamp"],
        nonce=headers["X-Nexora-Nonce"],
        body_hash=expected_body_hash,
    )
    expected_signature = hmac.new(
        secret.encode("utf-8"),
        canonical.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    assert headers["X-Nexora-Signature"] == expected_signature


def test_body_serialization_is_deterministic():
    payload = {"b": 2, "a": 1}
    body1 = serialize_body(payload)
    body2 = serialize_body(payload)
    assert body1 == body2
    assert body1 == json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")


def test_empty_body_sha256():
    headers = sign_request(
        access_key_id="nexora_ak_test",
        secret_access_key="nexora_sk_test",
        method="GET",
        path="/api/v1/health",
    )
    expected = hashlib.sha256(b"").hexdigest()
    assert headers["X-Nexora-Content-SHA256"] == expected
