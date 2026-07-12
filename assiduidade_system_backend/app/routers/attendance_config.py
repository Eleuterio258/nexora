"""
Configuração de métodos de assiduidade por tenant (rh.assiduidade),
consultada no Nexora ERP e cacheada localmente com TTL curto.

Ver proposta-arquitetura-assiduidade-erp.md secção 9 e
CONTRATO-INTEGRACAO-ERP.md secção 4.

Limitação conhecida: o erp_client usa uma única API Key de device global
(ERP_API_KEY), i.e. esta instância do FaceClock está associada a UM tenant do
Nexora ERP. A cache abaixo é por isso também global (não por tenant) — se no
futuro uma instância do FaceClock precisar de servir vários tenants do ERP em
simultâneo, isto tem de evoluir para múltiplas API Keys de device e cache por
tenant.
"""

import time
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status

from app.deps import ActorContext, get_actor
from app.erp_client import ERPUnavailableError, erp_client

router = APIRouter(tags=["Attendance Config"])

_CACHE_TTL_SECONDS = 60.0
_cache: dict[str, Any] | None = None
_cache_expires_at: float = 0.0


async def _get_config_cached() -> dict[str, Any]:
    global _cache, _cache_expires_at
    now = time.monotonic()
    if _cache is not None and now < _cache_expires_at:
        return _cache
    config = await erp_client.get_attendance_config()
    _cache = config
    _cache_expires_at = now + _CACHE_TTL_SECONDS
    return config


@router.get("/tenant/attendance-config")
async def get_tenant_attendance_config(
    actor: ActorContext = Depends(get_actor),
) -> dict[str, Any]:
    """Devolve a configuração de métodos de assiduidade do tenant (facial,
    fingerprint, qr_code, nfc, geolocation, offline, etc.), para a app/dashboard
    decidir que métodos mostrar ao colaborador."""
    try:
        return await _get_config_cached()
    except ERPUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"ERP indisponivel: {exc}",
        )
