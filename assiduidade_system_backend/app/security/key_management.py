"""
Provedor de chave local para criptografia biometrica.

O FaceClock opera 100% self-hosted; a unica origem de chave suportada e a
variavel de ambiente BIOMETRIC_ENCRYPTION_KEY. Nenhum servico cloud e usado.
"""

from __future__ import annotations

import logging
import os

log = logging.getLogger(__name__)


class EnvironmentKeyProvider:
    """Le a chave de uma variavel de ambiente."""

    def __init__(self, env_var: str = "BIOMETRIC_ENCRYPTION_KEY") -> None:
        self.env_var = env_var

    def get_key(self) -> bytes:
        key = os.getenv(self.env_var)
        if not key:
            raise RuntimeError(
                f"{self.env_var} nao configurada. Defina uma chave forte e unica de 32 bytes."
            )
        return key.encode("utf-8")


def get_key_provider(provider_name: str | None = None) -> EnvironmentKeyProvider:
    """Factory que sempre devolve o provedor local (unico suportado)."""
    from app.config import settings

    name = (provider_name or settings.biometric_key_provider).lower()
    if name != "environment":
        raise RuntimeError(
            f"Provedor de chave '{name}' nao suportado em modo self-hosted. "
            "Use BIOMETRIC_KEY_PROVIDER=environment."
        )
    return EnvironmentKeyProvider()
