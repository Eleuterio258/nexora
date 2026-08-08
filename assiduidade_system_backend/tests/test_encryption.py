"""Testes para criptografia em repouso de templates biométricos."""

import base64
import json

import pytest

from app.security import BiometricEncryption, get_biometric_encryption
from app.services.biometric import deserialize_embedding, serialize_embedding


def _make_enc(key: str = "test-key-32bytes-long-enough!!", key_id: str = "v1") -> BiometricEncryption:
    return BiometricEncryption.from_single_key(key, key_id=key_id)


class TestBiometricEncryption:
    def test_encrypt_decrypt_roundtrip(self):
        enc = _make_enc()
        plaintext = b"template-biometrico-sensivel"
        ciphertext = enc.encrypt(plaintext)

        assert ciphertext != plaintext
        assert ciphertext.startswith(b"enc:v2:")
        assert enc.decrypt(ciphertext) == plaintext

    def test_encrypt_decrypt_text_roundtrip(self):
        enc = _make_enc()
        plaintext = "dGVzdGU="
        ciphertext = enc.encrypt_text(plaintext)

        assert ciphertext != plaintext
        decoded = base64.b64decode(ciphertext)
        assert decoded.startswith(b"enc:v2:")
        assert enc.decrypt_text(ciphertext) == plaintext

    def test_decrypt_legacy_v1_data(self):
        # Cria um payload no formato antigo enc:v1: e verifica que ainda e legivel.
        enc = _make_enc()
        plaintext = b"dados-legacy"
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM

        aesgcm = AESGCM(enc._keyring["v1"])
        nonce = b"\x00" * enc.NONCE_SIZE
        ct = aesgcm.encrypt(nonce, plaintext, None)
        legacy_payload = enc.PREFIX_V1 + nonce + ct

        assert enc.decrypt(legacy_payload) == plaintext

    def test_decrypt_legacy_data_returns_unchanged(self):
        enc = _make_enc()
        legacy = b"dados-antigos-em-claro"
        assert enc.decrypt(legacy) == legacy

    def test_decrypt_text_legacy_data_returns_unchanged(self):
        enc = _make_enc()
        legacy = "dados-antigos-em-claro"
        assert enc.decrypt_text(legacy) == legacy

    def test_different_nonces_produce_different_ciphertexts(self):
        enc = _make_enc()
        plaintext = b"same-template"
        ct1 = enc.encrypt(plaintext)
        ct2 = enc.encrypt(plaintext)
        assert ct1 != ct2
        assert enc.decrypt(ct1) == enc.decrypt(ct2) == plaintext

    def test_short_key_is_derived(self):
        enc = _make_enc("short")
        plaintext = b"secret"
        ciphertext = enc.encrypt(plaintext)
        assert enc.decrypt(ciphertext) == plaintext

    def test_missing_key_raises(self):
        with pytest.raises(RuntimeError):
            BiometricEncryption.from_single_key(None)

    def test_tampered_ciphertext_fails(self):
        enc = _make_enc()
        ciphertext = bytearray(enc.encrypt(b"secret"))
        ciphertext[-1] ^= 0xFF
        with pytest.raises(ValueError):
            enc.decrypt(bytes(ciphertext))

    def test_keyring_rotation(self):
        key_v1 = "test-key-32bytes-long-enough!!"
        key_v2 = "new-key-32bytes-long-enough!!!"
        keyring = {
            "v1": key_v1.encode("utf-8"),
            "v2": key_v2.encode("utf-8"),
        }
        enc_old = BiometricEncryption(keyring, active_key_id="v1")
        enc_new = BiometricEncryption(keyring, active_key_id="v2")

        plaintext = b"sensitive"
        old_ciphertext = enc_old.encrypt(plaintext)
        assert old_ciphertext.startswith(b"enc:v2:\x02v1")
        assert enc_new.decrypt(old_ciphertext) == plaintext
        assert enc_new.encrypt(plaintext).startswith(b"enc:v2:\x02v2")


class TestEmbeddingSerializationEncryption:
    def test_serialize_embedding_encrypts_data(self):
        embedding = [0.1, 0.2, 0.3]
        blob = serialize_embedding(embedding)
        assert blob.startswith(b"enc:v2:")
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
