import hashlib
import hmac
import time
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


_ERP_TOKEN_CACHE_TTL_SECONDS = 60.0
_erp_token_cache: dict[str, tuple[float, ActorContext]] = {}


async def _validate_via_erp(token: str) -> ActorContext:
    """Resolve a identidade de um Bearer token delegando no Nexora ERP
    (`GET /api/auth/gateway/validate`, ver `erp_client.validate_bearer_token`)
    — o FaceClock não assina nem partilha segredo com os tokens do ERP, por
    isso não pode validá-los localmente. Cacheado por 60s por token (hash, não
    o valor em claro) para não bater no ERP a cada pedido.
    """
    from app.erp_client import ERPAuthError, ERPUnavailableError, erp_client

    cache_key = hashlib.sha256(token.encode()).hexdigest()
    now = time.monotonic()
    cached = _erp_token_cache.get(cache_key)
    if cached and now < cached[0]:
        return cached[1]

    try:
        result = await erp_client.validate_bearer_token(token)
    except ERPAuthError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticacao invalido.",
        )
    except ERPUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Nao foi possivel validar o token junto do ERP: {exc}",
        )

    if not result.get("id"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sem identificacao de utilizador.",
        )

    actor = ActorContext(id=result["id"], role=result.get("role") or "COLABORADOR", tenant_id=result.get("tenant_id"))
    _erp_token_cache[cache_key] = (now + _ERP_TOKEN_CACHE_TTL_SECONDS, actor)
    return actor


async def _get_actor_from_jwt(authorization: str | None) -> ActorContext | None:
    """Extrai o actor de um Bearer token — primeiro tenta como JWT local do
    FaceClock (compatibilidade/testes), depois delega no ERP."""
    if not authorization or not authorization.lower().startswith("bearer "):
        return None

    token = authorization[7:]
    local_actor = _decode_local_jwt(token)
    if local_actor:
        return local_actor
    return await _validate_via_erp(token)


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


def apply_tenant(stmt, actor: ActorContext, model) -> Any:
    """Aplica filtro por tenant a uma query SQLAlchemy quando o actor tiver tenant_id."""
    if actor.tenant_id:
        return stmt.where(model.tenant_id == actor.tenant_id)
    return stmt


def require_role(*allowed_roles: str):
    """Dependency factory que restringe um endpoint a roles específicas.

    Antes desta dependency, praticamente todos os endpoints `/admin/*`
    (excepto `authcode/admin/set-pin`) só exigiam QUALQUER identidade
    autenticada — o prefixo "/admin/" no caminho era só convenção de nome,
    não uma restrição real. Ver discussão em
    assiduidade_system_backend/CONTRATO-INTEGRACAO-ERP.md sobre esta lacuna.

    Uso: `dependencies=[Depends(require_role("ADMIN_SISTEMA", "GESTOR_RH"))]`.
    """

    def _dependency(actor: ActorContext = Depends(get_actor)) -> ActorContext:
        if actor.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Acesso restrito a: {', '.join(allowed_roles)}.",
            )
        return actor

    return _dependency


def require_not_production() -> None:
    """Dependency que bloqueia (403) um endpoint quando ENVIRONMENT=production.

    Fase 5: dados mestres (funcionários/unidades) passam a vir apenas do
    Nexora ERP via /sync/employees em produção — os endpoints de mutação
    directa (`POST/PATCH/DELETE /admin/users`, `/admin/units`) ficam
    read-only nesse ambiente, para não haver duas fontes de verdade.
    Fora de produção (dev/staging), continuam activos para conveniência.
    """
    from app.config import settings

    if settings.environment == "production":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Operação desactivada em produção — dados mestres (funcionários/unidades) "
                "vêm apenas do Nexora ERP via sincronização."
            ),
        )
