import hmac
from dataclasses import dataclass
from typing import Any

from fastapi import Depends, Header, HTTPException, status


@dataclass
class ActorContext:
    """Identidade do chamador, informada por JWT (app) ou pelo gateway
    via headers X-Auth-User-Id/X-Auth-User-Role/X-Auth-Tenant-Id, no formato
    devolvido por GET /api/auth/gateway/validate do Nexora ERP.
    """

    id: str | None
    role: str
    tenant_id: str | None = None


# Mapeamento de `tipo` (auth.users.tipo) do Nexora ERP para o UserRole do FaceClock.
# So aplicavel a quem consumir o `tipo` bruto do ERP directamente (ex.: sync de
# funcionarios); NAO e usado em get_actor(), porque X-Auth-User-Role e um header
# generico de identidade confiavel e pode ja vir com um role no vocabulario do
# FaceClock (COLABORADOR/GESTOR_RH/ADMIN_SISTEMA/AUDITOR), consoante o chamador.
# Ver contrato de integracao em assiduidade_system_backend/CONTRATO-INTEGRACAO-ERP.md.
ERP_ROLE_MAP: dict[str, str] = {
    "superadmin": "ADMIN_SISTEMA",
    "funcionario": "COLABORADOR",
    "aluno": "COLABORADOR",
    "encarregado": "COLABORADOR",
    "candidato": "COLABORADOR",
}


def map_erp_role(erp_tipo: str | None) -> str:
    """Traduz o `tipo` bruto do Nexora ERP para o UserRole local do FaceClock.

    Nota: o ERP ainda nao distingue GESTOR_RH/AUDITOR pelo `tipo` (so expoe
    tipo de conta, nao o cargo/permissoes RBAC completos) — falta refinar em
    Fase 1 quando houver necessidade real de conceder essas roles via gateway.
    """
    if not erp_tipo:
        return "COLABORADOR"
    return ERP_ROLE_MAP.get(erp_tipo.lower(), "COLABORADOR")


def _decode_local_jwt(token: str) -> ActorContext | None:
    """Tenta decifrar o token como um JWT assinado localmente pelo FaceClock.

    Devolve None (sem levantar excepção) se a assinatura/algoritmo não bater —
    isso não significa "token invalido", só que não é um token deste serviço;
    o chamador (`_get_actor_from_jwt`) tenta a seguir delegar a validação no
    ERP, que é agora a única origem de identidade (ver Fase 6,
    CONTRATO-INTEGRACAO-ERP.md secção 8.4 — o FaceClock deixou de emitir os
    seus próprios tokens de login).
    """
    import jwt as pyjwt

    from app.config import settings

    try:
        payload = pyjwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    except pyjwt.PyJWTError:
        return None

    if payload.get("type") != "access":
        return None
    user_id = payload.get("sub")
    if not user_id:
        return None

    role = payload.get("role") or "COLABORADOR"
    tenant_id = payload.get("tenant_id")
    return ActorContext(id=user_id, role=role, tenant_id=tenant_id)


def _role_from_erp_claims(payload: dict) -> str:
    """Traduz as claims do access token OAuth2 do ERP (tipo/scope) para o
    vocabulário de role do FaceClock — mesma regra que o ERP aplicava
    server-side em `gatewayAppRole` (auth.go) quando a identidade vinha por
    `GET /api/auth/gateway/validate`. Agora o FaceClock tem a claim `scope`
    (permissões RBAC finas, espaço-separadas, ou "*" para superadmin)
    directamente no token, por isso pode calcular isto sozinho, sem depender
    de um header já traduzido pelo ERP.
    """
    if payload.get("tipo") == "superadmin":
        return "ADMIN_SISTEMA"
    scope = (payload.get("scope") or "").split()
    if "*" in scope or "recursos-humanos:aprovar_ausencias" in scope:
        return "GESTOR_RH"
    return "COLABORADOR"


async def _validate_local_jwt(token: str) -> ActorContext:
    """Verifica um access token RS256 do Nexora ERP localmente via JWKS
    (`GET /oauth/jwks`, ver `app.oauth_jwks`) — sem round-trip. Substitui o
    antigo `_validate_via_erp` (round-trip a `GET /api/auth/gateway/validate`,
    ver `erp_client.validate_bearer_token`, removido): o ERP passou a assinar
    RS256 com uma chave por `kid`, publicada em JWKS, justamente para
    permitir isto.
    """
    import jwt as pyjwt

    from app.oauth_jwks import decode_erp_access_token

    try:
        payload = decode_erp_access_token(token)
    except pyjwt.PyJWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token invalido ou expirado: {exc}",
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sem identificacao de utilizador.",
        )

    tenant_id = payload.get("tid")
    return ActorContext(
        id=str(user_id),
        role=_role_from_erp_claims(payload),
        tenant_id=str(tenant_id) if tenant_id else None,
    )


async def _get_actor_from_jwt(authorization: str | None) -> ActorContext | None:
    """Extrai o actor de um Bearer token — primeiro tenta como JWT local do
    FaceClock (compatibilidade/testes), depois verifica como access token
    RS256 do ERP via JWKS local."""
    if not authorization or not authorization.lower().startswith("bearer "):
        return None

    token = authorization[7:]
    local_actor = _decode_local_jwt(token)
    if local_actor:
        return local_actor
    return await _validate_local_jwt(token)


def _check_gateway_secret(x_gateway_secret: str | None) -> None:
    """Valida o segredo partilhado entre o gateway/ERP e o FaceClock.

    Se GATEWAY_SHARED_SECRET estiver configurado (obrigatorio em producao, ver
    Settings.assert_production_secrets), qualquer pedido que traga headers de
    identidade de confianca (X-Auth-*) tem de o apresentar tambem — caso
    contrario um chamador com mero acesso de rede poderia forjar-se como
    qualquer utilizador/tenant so por conhecer os nomes dos headers.
    """
    from app.config import settings

    if not settings.gateway_shared_secret:
        return
    if not x_gateway_secret or not hmac.compare_digest(x_gateway_secret, settings.gateway_shared_secret):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Origem nao autorizada para headers de identidade de confianca.",
        )


async def get_actor(
    authorization: str | None = Header(default=None, alias="Authorization"),
    x_auth_user_id: str | None = Header(default=None, alias="X-Auth-User-Id"),
    x_auth_user_role: str | None = Header(default=None, alias="X-Auth-User-Role"),
    x_auth_tenant_id: str | None = Header(default=None, alias="X-Auth-Tenant-Id"),
    x_gateway_secret: str | None = Header(default=None, alias="X-Gateway-Secret"),
) -> ActorContext:
    """Resolve a identidade do chamador. Nunca devolve um actor anónimo — um
    pedido sem Bearer válido nem headers de gateway confiáveis é rejeitado
    com 401 (P0 da analise de seguranca: os endpoints biometricos nao podem
    ser alcancaveis sem identidade, porque apply_tenant() nao filtra quando
    tenant_id e None)."""
    jwt_actor = await _get_actor_from_jwt(authorization)
    if jwt_actor:
        return jwt_actor
    if x_auth_user_id:
        _check_gateway_secret(x_gateway_secret)
        return ActorContext(
            id=x_auth_user_id,
            role=x_auth_user_role or "SYSTEM",
            tenant_id=x_auth_tenant_id,
        )
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identidade nao fornecida: Bearer token ou headers de gateway em falta.",
    )


def apply_tenant(stmt, actor: ActorContext, model) -> Any:
    """Aplica filtro por tenant a uma query SQLAlchemy.

    ADMIN_SISTEMA (superadmin no ERP) pode legitimamente nao ter tenant_id
    (acesso cross-tenant). Qualquer outro role sem tenant_id e uma anomalia,
    nao uma consulta global — falha fechado (403) em vez de devolver dados
    de todos os tenants sem filtro.
    """
    if actor.role == "ADMIN_SISTEMA":
        return stmt
    if not actor.tenant_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Actor sem tenant identificado.",
        )
    return stmt.where(model.tenant_id == actor.tenant_id)


def require_self_or_manager(actor: ActorContext, target_user_id: str) -> None:
    """Impede que um COLABORADOR actue em nome de outro utilizador.

    Mesma regra ja aplicada em /clock/register antes de ser removido na
    limpeza stateless (ver CONTRATO-INTEGRACAO-ERP.md secção 8.5): qualquer
    role de gestor pode operar em nome de outrem do seu tenant; um
    colaborador comum só pode operar sobre a própria identidade.
    """
    if actor.id == target_user_id:
        return
    if actor.role in ("ADMIN_SISTEMA", "GESTOR_RH"):
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Nao pode realizar esta operacao em nome de outro utilizador.",
    )


