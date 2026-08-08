"""
Criptografia em repouso para dados biométricos.

Suporta dois formatos de payload:

    enc:v1:<nonce:12 bytes><tag:16 bytes><ciphertext>
    enc:v2:<key_id_len:1 byte><key_id><nonce:12 bytes><tag:16 bytes><ciphertext>

A v2 permite rotação de chaves: cada payload carrega o identificador da chave
usada, e o descodificador selecciona a chave correcta a partir de um keyring.

As chaves podem ser fornecidas por:
- `BIOMETRIC_ENCRYPTION_KEY` (única, default `key_id='v1'`)
- `BIOMETRIC_ENCRYPTION_KEYS` (JSON: {"v1": "base64key", "v2": "base64key", "active": "v2"})

A chave activa é usada para encriptar novos dados. Dados antigos continuam a
ser legidos com a chave correspondente ao `key_id`.
"""

import base64
import hashlib
import json
import secrets
from typing import ClassVar

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM


class BiometricEncryption:
    """Encriptacao/desencriptacao de templates biométricos com AES-256-GCM."""

    PREFIX_V1: ClassVar[bytes] = b"enc:v1:"
    PREFIX_V2: ClassVar[bytes] = b"enc:v2:"
    KEY_ID_LEN_SIZE: ClassVar[int] = 1
    NONCE_SIZE: ClassVar[int] = 12
    TAG_SIZE: ClassVar[int] = 16
    KEY_SIZE: ClassVar[int] = 32

    def __init__(self, keyring: dict[str, bytes], active_key_id: str) -> None:
        if not keyring:
            raise RuntimeError(
                "Nenhuma chave de encriptacao biométrica configurada. "
                "Defina BIOMETRIC_ENCRYPTION_KEY ou BIOMETRIC_ENCRYPTION_KEYS."
            )
        if active_key_id not in keyring:
            raise RuntimeError(
                f"Chave activa '{active_key_id}' nao encontrada no keyring."
            )

        self._keyring: dict[str, bytes] = {}
        for key_id, raw in keyring.items():
            self._keyring[key_id] = self._normalize_key(raw)

        self._active_key_id = active_key_id
        self._active_aesgcm = AESGCM(self._keyring[active_key_id])

    @classmethod
    def from_single_key(cls, key: bytes | str | None, key_id: str = "v1") -> "BiometricEncryption":
        if key is None:
            raise RuntimeError(
                "BIOMETRIC_ENCRYPTION_KEY nao configurada. "
                "Defina uma chave de 32 bytes antes de arrancar o servico."
            )
        raw = key.encode("utf-8") if isinstance(key, str) else key
        return cls({key_id: raw}, active_key_id=key_id)

    @classmethod
    def from_env_keys(
        cls,
        single_key: bytes | str | None,
        keys_json: str | None,
        default_key_id: str = "v1",
    ) -> "BiometricEncryption":
        """Constroi o keyring a partir das variaveis de ambiente.

        Preferencia:
        1. BIOMETRIC_ENCRYPTION_KEYS (JSON com keyring completo)
        2. BIOMETRIC_ENCRYPTION_KEY (chave unica)
        """
        if keys_json:
            try:
                config = json.loads(keys_json)
            except json.JSONDecodeError as exc:
                raise RuntimeError("BIOMETRIC_ENCRYPTION_KEYS nao e JSON valido.") from exc

            keyring: dict[str, bytes] = {}
            for key_id, value in config.items():
                if key_id == "active":
                    continue
                if isinstance(value, str):
                    keyring[key_id] = base64.b64decode(value)
                elif isinstance(value, (bytes, bytearray)):
                    keyring[key_id] = bytes(value)
                else:
                    raise RuntimeError(f"Formato de chave invalido para {key_id}.")

            active = config.get("active")
            if active is None:
                active = next(iter(keyring))
            if isinstance(active, str) and active not in keyring:
                raise RuntimeError(f"Chave activa '{active}' nao existe no keyring.")
            return cls(keyring, active_key_id=active)

        return cls.from_single_key(single_key, key_id=default_key_id)

    def _normalize_key(self, raw: bytes) -> bytes:
        if len(raw) < self.KEY_SIZE:
            # Deriva para 32 bytes — aceitavel apenas em dev.
            raw = hashlib.sha256(raw).digest()
        elif len(raw) > self.KEY_SIZE:
            raw = hashlib.sha256(raw).digest()
        return raw[: self.KEY_SIZE]

    def _get_aesgcm(self, key_id: str) -> AESGCM:
        key = self._keyring.get(key_id)
        if key is None:
            raise ValueError(f"unknown_key_id:{key_id}")
        return AESGCM(key)

    def encrypt(self, plaintext: bytes) -> bytes:
        """Encripta bytes e devolve payload no formato `enc:v2:...`."""
        key_id_bytes = self._active_key_id.encode("ascii")
        if len(key_id_bytes) > 255:
            raise RuntimeError("key_id must be <= 255 ASCII characters")

        key_id_len = len(key_id_bytes).to_bytes(self.KEY_ID_LEN_SIZE, "big")
        nonce = secrets.token_bytes(self.NONCE_SIZE)
        ciphertext = self._active_aesgcm.encrypt(nonce, plaintext, None)
        return self.PREFIX_V2 + key_id_len + key_id_bytes + nonce + ciphertext

    def decrypt(self, payload: bytes) -> bytes:
        """
        Desencripta payload nos formatos `enc:v1:` ou `enc:v2:`.
        Se nao tiver prefixo, assume dado legado e devolve-o como esta.
        """
        if payload.startswith(self.PREFIX_V1):
            key_id = "v1"
            rest = payload[len(self.PREFIX_V1) :]
        elif payload.startswith(self.PREFIX_V2):
            rest = payload[len(self.PREFIX_V2) :]
            if len(rest) < self.KEY_ID_LEN_SIZE + self.NONCE_SIZE + self.TAG_SIZE:
                raise ValueError("encrypted_payload_too_short")
            key_id_len = int.from_bytes(rest[: self.KEY_ID_LEN_SIZE], "big")
            rest = rest[self.KEY_ID_LEN_SIZE :]
            if len(rest) < key_id_len + self.NONCE_SIZE + self.TAG_SIZE:
                raise ValueError("encrypted_payload_too_short")
            key_id = rest[:key_id_len].decode("ascii")
            rest = rest[key_id_len:]
        else:
            return payload

        if len(rest) < self.NONCE_SIZE + self.TAG_SIZE:
            raise ValueError("encrypted_payload_too_short")
        nonce = rest[: self.NONCE_SIZE]
        ciphertext = rest[self.NONCE_SIZE :]

        aesgcm = self._get_aesgcm(key_id)
        try:
            return aesgcm.decrypt(nonce, ciphertext, None)
        except InvalidTag as exc:
            raise ValueError("invalid_authentication_tag") from exc

    def encrypt_text(self, plaintext: str) -> str:
        """Encripta texto (ex.: template base64) e devolve string base64."""
        encrypted = self.encrypt(plaintext.encode("utf-8"))
        return base64.b64encode(encrypted).decode("ascii")

    def decrypt_text(self, payload: str) -> str:
        """Desencripta texto; se nao estiver encriptado, devolve como esta."""
        try:
            raw = base64.b64decode(payload)
        except Exception:
            return payload
        if not raw.startswith(self.PREFIX_V1) and not raw.startswith(self.PREFIX_V2):
            return payload
        return self.decrypt(raw).decode("utf-8")

    @property
    def active_key_id(self) -> str:
        return self._active_key_id


def get_biometric_encryption() -> BiometricEncryption:
    """Factory que le as chaves da configuracao global."""
    from app.config import settings

    return BiometricEncryption.from_env_keys(
        single_key=settings.biometric_encryption_key,
        keys_json=settings.biometric_encryption_keys,
    )
