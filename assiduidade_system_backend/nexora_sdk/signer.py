"""Cálculo da assinatura HMAC-SHA256 Nexora."""

import hashlib
import hmac
import json
import time
import urllib.parse
import uuid
from typing import Any

NEXORA_ACCESS_KEY_HEADER = "X-Nexora-Access-Key"
NEXORA_TIMESTAMP_HEADER = "X-Nexora-Timestamp"
NEXORA_NONCE_HEADER = "X-Nexora-Nonce"
NEXORA_CONTENT_SHA256_HEADER = "X-Nexora-Content-SHA256"
NEXORA_SIGNATURE_HEADER = "X-Nexora-Signature"
NEXORA_AUTH_VERSION_HEADER = "X-Nexora-Auth-Version"


def _canonical_query_string(query: str) -> str:
    """Normaliza uma query string para a mensagem canónica."""
    if not query:
        return ""
    params = urllib.parse.parse_qsl(query, keep_blank_values=True)
    sorted_params = sorted(params, key=lambda item: item[0])
    return urllib.parse.urlencode(sorted_params, doseq=True, quote_via=urllib.parse.quote)


def serialize_body(payload: Any) -> bytes:
    """Serializa o payload em JSON de forma determinística."""
    if payload is None:
        return b""
    if isinstance(payload, bytes):
        return payload
    if isinstance(payload, str):
        return payload.encode("utf-8")
    return json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")


def canonical_string(
    method: str,
    path: str,
    query: str,
    timestamp: str,
    nonce: str,
    body_hash: str,
) -> str:
    """Constrói a mensagem canónica Nexora HMAC-SHA256."""
    return (
        f"{method.upper()}\n"
        f"{path}\n"
        f"{_canonical_query_string(query)}\n"
        f"{timestamp}\n"
        f"{nonce}\n"
        f"{body_hash}"
    )


def sign_request(
    access_key_id: str,
    secret_access_key: str,
    method: str,
    path: str,
    query: str = "",
    payload: Any = None,
    auth_version: str = "NEXORA-HMAC-SHA256-V1",
) -> dict[str, str]:
    """Assina um pedido HTTP e devolve os headers de autenticação Nexora.

    Args:
        access_key_id: identificador público da credencial.
        secret_access_key: chave secreta (nunca enviada pela rede).
        method: método HTTP (GET, POST, etc.).
        path: caminho absoluto do endpoint (ex.: /api/biometric/verify).
        query: query string raw ou string vazia.
        payload: body do pedido (dict/list/str/bytes/None).
        auth_version: versão do protocolo.

    Returns:
        Dicionário com os headers a adicionar ao pedido HTTP.
    """
    body = serialize_body(payload)
    body_hash = hashlib.sha256(body).hexdigest()
    timestamp = str(int(time.time()))
    nonce = str(uuid.uuid4())

    canonical = canonical_string(method, path, query, timestamp, nonce, body_hash)
    signature = hmac.new(
        secret_access_key.encode("utf-8"),
        canonical.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    return {
        NEXORA_ACCESS_KEY_HEADER: access_key_id,
        NEXORA_TIMESTAMP_HEADER: timestamp,
        NEXORA_NONCE_HEADER: nonce,
        NEXORA_CONTENT_SHA256_HEADER: body_hash,
        NEXORA_SIGNATURE_HEADER: signature,
        NEXORA_AUTH_VERSION_HEADER: auth_version,
        "Content-Type": "application/json",
    }
