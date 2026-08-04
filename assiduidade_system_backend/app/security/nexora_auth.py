"""Autenticação Nexora via HMAC-SHA256 para comunicação serviço-a-serviço.

A chave secreta (NEXORA_SECRET_ACCESS_KEY) nunca transmite na rede.
Cada pedido é assinado com:
  - X-Nexora-Access-Key: identificador público da credencial
  - X-Nexora-Timestamp: epoch seconds
  - X-Nexora-Nonce: nonce único (previne replay)
  - X-Nexora-Content-SHA256: hash SHA-256 do body
  - X-Nexora-Signature: HMAC-SHA256 da mensagem canónica
  - X-Nexora-Auth-Version: versão do protocolo (opcional, recomendado)

Mensagem canónica:
  HTTP_METHOD
  REQUEST_PATH
  CANONICAL_QUERY_STRING
  TIMESTAMP
  NONCE
  BODY_SHA256

O receptor valida:
  1. HTTPS em produção
  2. headers obrigatórios presentes
  3. timestamp dentro do TTL (default 300s)
  4. nonce não reutilizado (Redis)
  5. credencial ativa e não expirada
  6. hash do body coincide
  7. HMAC coincide
  8. permissões suficientes
  9. tenant correto
"""

import hashlib
import hmac
import secrets
import time
import urllib.parse
from collections.abc import Callable
from typing import Any

from fastapi import Depends, Header, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.deps import ActorContext
from app.redis_client import get_redis
from app.services.api_credentials import get_active_credential, touch_last_used


NEXORA_ACCESS_KEY_HEADER = "X-Nexora-Access-Key"
NEXORA_TIMESTAMP_HEADER = "X-Nexora-Timestamp"
NEXORA_NONCE_HEADER = "X-Nexora-Nonce"
NEXORA_CONTENT_SHA256_HEADER = "X-Nexora-Content-SHA256"
NEXORA_SIGNATURE_HEADER = "X-Nexora-Signature"
NEXORA_AUTH_VERSION_HEADER = "X-Nexora-Auth-Version"

_AUTH_ERROR = "Credenciais de autenticação inválidas ou requisição não autorizada."
_PERMISSION_ERROR = "Sem permissão para executar esta operação."


class NexoraAuth:
    """Assina e valida pedidos entre sistemas Nexora via HMAC-SHA256."""

    def __init__(
        self,
        access_key_id: str,
        secret_access_key: str,
        ttl_seconds: int = 300,
    ) -> None:
        if not access_key_id or not secret_access_key:
            raise RuntimeError(
                "NEXORA_ACCESS_KEY_ID e NEXORA_SECRET_ACCESS_KEY são obrigatórios."
            )
        self.access_key_id = access_key_id
        self.secret_access_key = secret_access_key.encode("utf-8")
        self.ttl_seconds = ttl_seconds

    @staticmethod
    def _canonical_query_string(query: str) -> str:
        """Normaliza uma query string para a mensagem canónica."""
        if not query:
            return ""
        params = urllib.parse.parse_qsl(query, keep_blank_values=True)
        sorted_params = sorted(params, key=lambda item: item[0])
        return urllib.parse.urlencode(sorted_params, doseq=True, quote_via=urllib.parse.quote)

    def _canonical_string(
        self,
        method: str,
        path: str,
        query: str,
        body: bytes | None,
        timestamp: str,
        nonce: str,
    ) -> str:
        body = body or b""
        body_hash = hashlib.sha256(body).hexdigest()
        canonical_query = self._canonical_query_string(query)
        return (
            f"{method.upper()}\n"
            f"{path}\n"
            f"{canonical_query}\n"
            f"{timestamp}\n"
            f"{nonce}\n"
            f"{body_hash}"
        )

    def sign_request(
        self,
        method: str,
        path: str,
        query: str = "",
        body: bytes | None = None,
        access_key_id: str | None = None,
    ) -> dict[str, str]:
        """Gera os headers de assinatura para um pedido outgoing."""
        timestamp = str(int(time.time()))
        nonce = secrets.token_hex(16)  # 32 caracteres hex
        canonical = self._canonical_string(method, path, query, body, timestamp, nonce)
        signature = hmac.new(
            self.secret_access_key,
            canonical.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()
        body = body or b""
        return {
            NEXORA_ACCESS_KEY_HEADER: access_key_id or self.access_key_id,
            NEXORA_TIMESTAMP_HEADER: timestamp,
            NEXORA_NONCE_HEADER: nonce,
            NEXORA_CONTENT_SHA256_HEADER: hashlib.sha256(body).hexdigest(),
            NEXORA_SIGNATURE_HEADER: signature,
            NEXORA_AUTH_VERSION_HEADER: settings.nexora_auth_version,
            "Content-Type": "application/json",
        }


def _is_https(request: Request) -> bool:
    """Verifica se o pedido chegou por HTTPS, incluindo proxies."""
    if request.url.scheme == "https":
        return True
    forwarded_proto = request.headers.get("x-forwarded-proto")
    if forwarded_proto == "https":
        return True
    return False


def _consume_nonce(access_key_id: str, nonce: str, ttl_seconds: int) -> bool:
    """Regista o nonce no Redis. Devolve True se for novo, False se já existir."""
    key = f"nexora:nonce:{access_key_id}:{nonce}"
    try:
        redis_client = get_redis()
        result = redis_client.set(key, "1", nx=True, ex=max(ttl_seconds, 300))
        return result is not None
    except Exception:
        # Se o Redis falhar, falhamos fechado para evitar replay não detetado.
        return False


def _unauthorized() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=_AUTH_ERROR,
    )


def _require_nexora_signature(
    permission: str,
) -> Callable[..., Any]:
    """Factory de dependências FastAPI para exigir assinatura Nexora válida."""

    async def dependency(
        request: Request,
        db: Session = Depends(get_db),
        x_nexora_access_key: str | None = Header(default=None, alias=NEXORA_ACCESS_KEY_HEADER),
        x_nexora_timestamp: str | None = Header(default=None, alias=NEXORA_TIMESTAMP_HEADER),
        x_nexora_nonce: str | None = Header(default=None, alias=NEXORA_NONCE_HEADER),
        x_nexora_content_sha256: str | None = Header(default=None, alias=NEXORA_CONTENT_SHA256_HEADER),
        x_nexora_signature: str | None = Header(default=None, alias=NEXORA_SIGNATURE_HEADER),
    ) -> ActorContext:
        # 1. HTTPS em produção
        if (
            settings.environment == "production"
            and settings.nexora_hmac_require_https
            and not _is_https(request)
        ):
            raise _unauthorized()

        # 2. Headers obrigatórios
        if (
            not x_nexora_access_key
            or not x_nexora_timestamp
            or not x_nexora_nonce
            or not x_nexora_content_sha256
            or not x_nexora_signature
        ):
            raise _unauthorized()

        # 3. Timestamp
        try:
            ts = int(x_nexora_timestamp)
        except ValueError:
            raise _unauthorized()

        now = int(time.time())
        if abs(now - ts) > settings.nexora_signature_ttl_seconds:
            raise _unauthorized()

        # 4. Nonce (proteção replay)
        if not _consume_nonce(
            x_nexora_access_key,
            x_nexora_nonce,
            settings.nexora_signature_ttl_seconds,
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=_AUTH_ERROR,
            )

        # 5. Credencial ativa
        result = get_active_credential(db, x_nexora_access_key)
        if not result:
            raise _unauthorized()

        credential, secret = result

        # 6. Hash do body
        body = await request.body()
        expected_body_hash = hashlib.sha256(body).hexdigest()

        # Re-injectar o body no request para que o parser Pydantic dos routers
        # possa ler novamente.
        async def _receive() -> dict:
            return {"type": "http.request", "body": body}

        request._receive = _receive
        if not hmac.compare_digest(expected_body_hash, x_nexora_content_sha256):
            raise _unauthorized()

        # 7. Reconstruir mensagem canónica e assinatura
        auth = NexoraAuth(credential.access_key_id, secret, settings.nexora_signature_ttl_seconds)
        canonical = auth._canonical_string(
            method=request.method,
            path=request.url.path,
            query=request.url.query,
            body=body,
            timestamp=x_nexora_timestamp,
            nonce=x_nexora_nonce,
        )
        expected_signature = hmac.new(
            secret.encode("utf-8"),
            canonical.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

        if not hmac.compare_digest(x_nexora_signature, expected_signature):
            raise _unauthorized()

        # 8. Permissões
        if permission and permission not in credential.permissions:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=_PERMISSION_ERROR,
            )

        # 9. Registar último uso (sem logar segredos)
        touch_last_used(db, credential)

        return ActorContext(
            id=None,
            role="SYSTEM",
            tenant_id=credential.tenant_id,
        )

    return dependency


def require_nexora_signature(permission: str) -> Any:
    """Dependência FastAPI reutilizável que exige assinatura Nexora válida.

    Uso:
        @router.post("/biometric/verify")
        def verify(
            payload: VerifyRequest,
            actor: ActorContext = Depends(require_nexora_signature("biometric:verify")),
        ):
            ...
    """
    return Depends(_require_nexora_signature(permission))
