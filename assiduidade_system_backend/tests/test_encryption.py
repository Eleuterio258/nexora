"""Testes para criptografia em repouso de templates biométricos."""

import base64
import json

import pytest

from app.security import BiometricEncryption, get_biometric_encryption
from app.services.biometric import deserialize_embedding, serialize_embedding


class TestBiometricEncryption:
    def test_encrypt_decrypt_roundtrip(self):
        enc = BiometricEncryption("test-key-32bytes-long-enough!!")
        plaintext = b"template-biometrico-sensivel"
        ciphertext = enc.encrypt(plaintext)

        assert ciphertext != plaintext
        assert ciphertext.startswith(b"enc:v1:")
        assert enc.decrypt(ciphertext) == plaintext

    def test_encrypt_decrypt_text_roundtrip(self):
        enc = BiometricEncryption("test-key-32bytes-long-enough!!")
        plaintext = "dGVzdGU="
        ciphertext = enc.encrypt_text(plaintext)

        assert ciphertext != plaintext
        assert ciphertext.startswith("enc:v1:")
        assert enc.decrypt_text(ciphertext) == plaintext

    def test_decrypt_legacy_data_returns_unchanged(self):
        enc = BiometricEncryption("test-key-32bytes-long-enough!!")
        legacy = b"dados-antigos-em-claro"
        assert enc.decrypt(legacy) == legacy

    def test_decrypt_text_legacy_data_returns_unchanged(self):
        enc = BiometricEncryption("test-key-32bytes-long-enough!!")
        legacy = "dados-antigos-em-claro"
        assert enc.decrypt_text(legacy) == legacy

    def test_different_nonces_produce_different_ciphertexts(self):
        enc = BiometricEncryption("test-key-32bytes-long-enough!!")
        plaintext = b"same-template"
        ct1 = enc.encrypt(plaintext)
        ct2 = enc.encrypt(plaintext)
        assert ct1 != ct2
        assert enc.decrypt(ct1) == enc.decrypt(ct2) == plaintext

    def test_short_key_is_derived(self):
        enc = BiometricEncryption("short")
        plaintext = b"secret"
        ciphertext = enc.encrypt(plaintext)
        assert enc.decrypt(ciphertext) == plaintext

    def test_missing_key_raises(self):
        with pytest.raises(RuntimeError):
            BiometricEncryption(None)

    def test_tampered_ciphertext_fails(self):
        enc = BiometricEncryption("test-key-32bytes-long-enough!!")
        ciphertext = bytearray(enc.encrypt(b"secret"))
        ciphertext[-1] ^= 0xFF
        with pytest.raises(ValueError):
            enc.decrypt(bytes(ciphertext))


class TestEmbeddingSerializationEncryption:
    def test_serialize_embedding_encrypts_data(self):
        embedding = [0.1, 0.2, 0.3]
        blob = serialize_embedding(embedding)
        assert blob.startswith(b"enc:v1:")
        assert json.dumps(embedding).encode("utf-8") not in blob

    def test_deserialize_embedding_decrypts_data(self):
        embedding = [0.1, 0.2, 0.3]
        blob = serialize_embedding(embedding)
        result = deserialize_embedding(blob)
        assert result == pytest.approx(embedding)

    def test_deserialize_legacy_embedding_still_works(self):
        embedding = [0.1, 0.2, 0.3]
        legacy_blob = json.dumps(embedding, separators=(",", ":")).encode("utf-8")
        result = deserialize_embedding(legacy_blob)
        assert result == pytest.approx(embedding)

    def test_get_biometric_encryption_uses_settings(self):
        enc = get_biometric_encryption()
        plaintext = b"integration-check"
        assert enc.decrypt(enc.encrypt(plaintext)) == plaintext
