"""
Validação de métodos de assiduidade contra a configuração por tenant
(rh.assiduidade) do Nexora ERP — Fase 3 da integração.

Ver proposta-arquitetura-assiduidade-erp.md secção 9.6 e
CONTRATO-INTEGRACAO-ERP.md.
"""

import time
from typing import Any

from fastapi import HTTPException, status

from app.erp_client import ERPUnavailableError, erp_client
from app.schemas.common import SourceType

_CACHE_TTL_SECONDS = 60.0
_cache: dict[str, Any] | None = None
_cache_expires_at: float = 0.0


async def _get_config_cached() -> dict[str, Any]:
    """Cache em memória (60s) da config de assiduidade do ERP — evita bater
    no ERP a cada chamada de `/biometric/verify`/`/liveness/verify`. Movido
    para aqui em 2026-07-13 quando `app/routers/attendance_config.py` (o
    endpoint HTTP `GET /tenant/attendance-config`) foi removido; este cache
    já não serve nenhum endpoint, só esta validação interna.
    """
    global _cache, _cache_expires_at
    now = time.monotonic()
    if _cache is not None and now < _cache_expires_at:
        return _cache
    config = await erp_client.get_attendance_config()
    _cache = config
    _cache_expires_at = now + _CACHE_TTL_SECONDS
    return config

# SourceType do FaceClock -> chave de método na configuração do ERP.
# ONLINE/OFFLINE_SYNC/INTEGRATION são modos de transporte do registo (como o
# evento chegou ao servidor), não métodos biométricos/alternativos — por isso
# não têm entrada aqui e nunca são bloqueados por esta validação.
_SOURCE_TO_METODO: dict[SourceType, str] = {
    SourceType.FACIAL: "facial",
    SourceType.FINGERPRINT: "fingerprint",
    SourceType.QR_CODE: "qr_code",
    SourceType.NFC: "nfc",
    # SELFIE_GPS = método 6 da spec ("Selfie com Prova de Vida", desafio de
    # acção + match facial) — chave própria "selfie", distinta de
    # "geolocation" (método 4, GPS+Geofencing puro). Antes desta correcção
    # estava indevidamente fundido com "geolocation"; corrigido ao implementar
    # o desafio de vivacidade real em app/services/liveness_challenge.py.
    SourceType.SELFIE_GPS: "selfie",
    SourceType.GEOLOCATION: "geolocation",
    SourceType.PIN: "pin",
    SourceType.MANUAL: "manual",
}


async def validar_metodo_assiduidade(source: SourceType) -> None:
    """Levanta HTTP 403 se o método `source` estiver explicitamente
    desactivado para o tenant, segundo a configuração `rh.assiduidade` do ERP.

    Decisões de "falhar aberto" (permitir), documentadas propositadamente:
    - `source` sem mapeamento (ONLINE/OFFLINE_SYNC/INTEGRATION): não é um
      método validável, sempre permitido.
    - Método sem entrada explícita no JSON de configuração (ex.: admin ainda
      não configurou "pin"/"manual"): permitido, para não quebrar clientes
      antes de existir configuração completa.
    - ERP indisponível (`ERPUnavailableError`) ou tenant sem `rh.assiduidade`
      activa: permitido, para não tornar `/clock/register` indisponível só
      porque o ERP está em baixo ou a integração não está activa para esse
      tenant. Quem quiser bloquear estritamente deve activar isso explicitamente
      na configuração do método.
    """
    metodo = _SOURCE_TO_METODO.get(source)
    if metodo is None:
        return

    try:
        config = await _get_config_cached()
    except ERPUnavailableError:
        return

    metodos = (config.get("configuracao") or {}).get("metodos") or {}
    metodo_cfg = metodos.get(metodo)
    if metodo_cfg is None:
        return
    if not metodo_cfg.get("ativo", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Método de assiduidade '{metodo}' não permitido para este tenant.",
        )
