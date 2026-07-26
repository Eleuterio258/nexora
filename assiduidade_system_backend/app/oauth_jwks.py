"""Verificação local (sem round-trip) de access tokens RS256 emitidos pelo
Authorization Server do Nexora ERP (POST /oauth/token), via JWKS
(GET /oauth/jwks). Substitui o antigo caminho `erp_client.validate_bearer_token`
(round-trip a `GET /api/auth/gateway/validate`, ver deps.py:_validate_via_erp
na versão anterior) — o ERP passou a assinar com RS256 justamente para
permitir isto.
"""

from functools import lru_cache

import jwt as pyjwt
from jwt import PyJWKClient

from app.config import settings


@lru_cache(maxsize=1)
def _jwks_client() -> PyJWKClient:
    # PyJWKClient já faz cache interno do JWKS (lifespan) e só volta a pedir
    # ao ERP quando encontra um "kid" desconhecido — cobre rotação de chave
    # sem reinício do FaceClock. lifespan curto (1h) porque o custo de um
    # cache-miss é só uma chamada HTTP extra ao /oauth/jwks, não ao
    # utilizador final.
    return PyJWKClient(settings.erp_jwks_url, lifespan=3600)


def decode_erp_access_token(token: str) -> dict:
    """Verifica assinatura RS256 + claims standard (exp/aud) localmente.
    Levanta jwt.PyJWTError (ou subclasses) se o token for inválido,
    expirado, ou não corresponder a nenhuma chave publicada em /oauth/jwks —
    quem chama trata isso como token inválido (ver deps._validate_local_jwt).
    """
    signing_key = _jwks_client().get_signing_key_from_jwt(token)
    return pyjwt.decode(
        token,
        signing_key.key,
        algorithms=["RS256"],
        audience=settings.erp_token_audience,
        leeway=30,  # tolerância a relógio dessincronizado entre containers
        # O backend Go emite "sub" como número (int64 do user_id), não como
        # string — é o mesmo claim já lido em todo o middleware Go via
        # claims["sub"].(float64). O PyJWT, por omissão, rejeita "sub"
        # numérico (RFC 7519 recomenda string, mas não obriga; não vale a
        # pena mudar o tipo em todo o lado Go só por isto).
        options={"verify_sub": False},
    )
