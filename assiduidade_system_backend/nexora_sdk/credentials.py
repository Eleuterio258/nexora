"""Resolução de credenciais Nexora.

Ordem de precedência:
1. Parâmetros passados diretamente ao cliente.
2. Variáveis de ambiente.
3. Ficheiro de configuração Nexora (~/.nexora/credentials ou .nexora/credentials).
"""

import os
from dataclasses import dataclass
from pathlib import Path

from .exceptions import NexoraConfigError


@dataclass
class Credentials:
    access_key_id: str
    secret_access_key: str
    base_url: str


def _load_credentials_file(path: Path) -> dict[str, str] | None:
    """Lê um ficheiro de credenciais no formato INI simples.

    Exemplo de conteúdo:
        [default]
        access_key_id = nexora_ak_xxx
        secret_access_key = nexora_sk_xxx
        base_url = https://api.nexora.co.mz
    """
    if not path.exists():
        return None

    import configparser

    parser = configparser.ConfigParser()
    parser.read(path)
    if not parser.has_section("default"):
        return None

    return {
        "access_key_id": parser.get("default", "access_key_id", fallback=""),
        "secret_access_key": parser.get("default", "secret_access_key", fallback=""),
        "base_url": parser.get("default", "base_url", fallback=""),
    }


def _find_credentials_file() -> dict[str, str] | None:
    """Procura por ficheiros de configuração Nexora."""
    candidates = [
        Path(".nexora/credentials"),
        Path.home() / ".nexora" / "credentials",
    ]
    for candidate in candidates:
        data = _load_credentials_file(candidate)
        if data:
            return data
    return None


def resolve_credentials(
    access_key_id: str | None = None,
    secret_access_key: str | None = None,
    base_url: str | None = None,
) -> Credentials:
    """Resolve as credenciais a usar para assinar pedidos Nexora."""
    # 1. Parâmetros
    creds = {
        "access_key_id": access_key_id,
        "secret_access_key": secret_access_key,
        "base_url": base_url,
    }

    # 2. Variáveis de ambiente
    if not creds["access_key_id"]:
        creds["access_key_id"] = os.getenv("NEXORA_ACCESS_KEY_ID", "")
    if not creds["secret_access_key"]:
        creds["secret_access_key"] = os.getenv("NEXORA_SECRET_ACCESS_KEY", "")
    if not creds["base_url"]:
        creds["base_url"] = os.getenv("NEXORA_API_URL", "")

    # 3. Ficheiro de configuração
    if not all(creds.values()):
        file_creds = _find_credentials_file()
        if file_creds:
            if not creds["access_key_id"]:
                creds["access_key_id"] = file_creds.get("access_key_id", "")
            if not creds["secret_access_key"]:
                creds["secret_access_key"] = file_creds.get("secret_access_key", "")
            if not creds["base_url"]:
                creds["base_url"] = file_creds.get("base_url", "")

    # Validação
    missing = [k for k, v in creds.items() if not v]
    if missing:
        raise NexoraConfigError(
            f"Credenciais Nexora em falta: {', '.join(missing)}. "
            "Defina via parâmetros, variáveis de ambiente ou ficheiro ~/.nexora/credentials."
        )

    return Credentials(
        access_key_id=creds["access_key_id"],
        secret_access_key=creds["secret_access_key"],
        base_url=creds["base_url"].rstrip("/"),
    )
