"""
Criptografia em repouso para dados biométricos.

Usa AES-256-GCM com um nonce aleatório por registo. O formato em disco é:

    enc:v1:<nonce:12 bytes><tag:16 bytes><ciphertext>

A chave (`BIOMETRIC_ENCRYPTION_KEY`) deve ter 32 bytes (256 bits) em producao.
Se for mais curta, é derivada via SHA-256 para garantir tamanho correcto — isto
é util durante desenvolvimento/testes, mas em producao a chave deve ser forte
e gerida fora do codigo (ex.: variavel de ambiente ou secret manager).

A classe mantém compatibilidade com dados antigos em claro: ao desencriptar,
se o prefixo `enc:v1:` nao for encontrado, assume que o dado é legado (JSON ou
base64) e devolve-o sem alteracoes.
"""

import hashlib
import os
import secrets
from typing import ClassVar

from cryptography.hazmat.primitives.ciphers.aead import AESGCM


class BiometricEncryption:
    """Encriptacao/desencriptacao de templates biométricos com AES-256-GCM."""

    PREFIX: ClassVar[bytes] = b"enc:v1:"
    NONCE_SIZE: ClassVar[int] = 12
    TAG_SIZE: ClassVar[int] = 16
    KEY_SIZE: ClassVar[int] = 32

    def __init__(self, key: bytes | str | None) -> None:
        if key is None:
            raise RuntimeError(
                "BIOMETRIC_ENCRYPTION_KEY nao configurada. "
                "Defina uma chave de 32 bytes antes de arrancar o servico."
            )
        raw = key.encode("utf-8") if isinstance(key, str) else key
        if len(raw) < self.KEY_SIZE:
            # Deriva para 32 bytes — aceitavel apenas em dev; em producao a chave
            # deve ser fornecida com tamanho completo.
            raw = hashlib.sha256(raw).digest()
        elif len(raw) > self.KEY_SIZE:
            raw = hashlib.sha256(raw).digest()
        self._key = raw[: self.KEY_SIZE]
        self._aesgcm = AESGCM(self._key)

    def encrypt(self, plaintext: bytes) -> bytes:
        """Encripta bytes e devolve payload no formato `enc:v1:...`."""
        nonce = secrets.token_bytes(self.NONCE_SIZE)
        ciphertext = self._aesgcm.encrypt(nonce, plaintext, None)
        # AESGCM devolve ciphertext + tag no final
        return self.PREFIX + nonce + ciphertext

    def decrypt(self, payload: bytes) -> bytes:
        """
        Desencripta payload no formato `enc:v1:...`.
        Se nao tiver prefixo, assume dado legado e devolve-o como esta.
        """
        if not payload.startswith(self.PREFIX):
            return payload
        rest = payload[len(self.PREFIX) :]
        if len(rest) < self.NONCE_SIZE + self.TAG_SIZE:
            raise ValueError("encrypted_payload_too_short")
        nonce = rest[: self.NONCE_SIZE]
        ciphertext = rest[self.NONCE_SIZE :]
        return self._aesgcm.decrypt(nonce, ciphertext, None)

    def encrypt_text(self, plaintext: str) -> str:
        """Encripta texto (ex.: template base64) e devolve string com prefixo."""
        return self.encrypt(plaintext.encode("utf-8")).decode("utf-8")

    def decrypt_text(self, payload: str) -> str:
        """Desencripta texto; se nao estiver encriptado, devolve como esta."""
        return self.decrypt(payload.encode("utf-8")).decode("utf-8")


def get_biometric_encryption() -> BiometricEncryption:
    """Factory que le a chave da configuracao global."""
    from app.config import settings

    return BiometricEncryption(settings.biometric_encryption_key)
