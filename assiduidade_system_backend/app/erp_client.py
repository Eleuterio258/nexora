"""
Cliente HTTP para integração com o Nexora ERP.

Autenticação do FaceClock para utilizadores e integrações passou a ser feita
por Nexora HMAC (app/security/nexora_auth.py). Este cliente mantém-se apenas
para chamadas serviço-a-serviço do FaceClock ao ERP, usando API Key de device:
- Configuração de métodos de assiduidade.
- Proxies de consentimentos LGPD.
- Proxy de audit-logs.
- Notificação de re-enrolamento automático (best-effort).

Quando o ERP não está configurado ou está indisponível, as operações
levantam ERPUnavailableError para que o chamador possa decidir sobre fallback.
"""

import logging
from typing import Any

import httpx

from app.config import settings

log = logging.getLogger(__name__)


class ERPUnavailableError(Exception):
    """ERP não responde ou não está configurado."""


class ERPResponseError(Exception):
    """O ERP respondeu com um erro (4xx/5xx) a reencaminhar tal-qual ao chamador.

    Usado pelos proxies do ERP (self-service, geofence, consentimentos, qr,
    nfc, audit-logs), cujo contrato de erro (`{"error": "..."}`, vários status
    possíveis: 400/401/403/404) não se resume a "indisponível" ou "credenciais
    inválidas" — o FaceClock devolve o mesmo status/mensagem do ERP em vez de
    os achatar.
    """

    def __init__(self, status_code: int, detail: str) -> None:
        self.status_code = status_code
        self.detail = detail
        super().__init__(detail)


class ERPClient:
    def __init__(self) -> None:
        self.base_url = settings.erp_base_url.rstrip("/")
        self.api_key = settings.erp_api_key
        self.timeout = settings.erp_timeout_seconds

    def _headers(self) -> dict[str, str]:
        """Headers para chamadas de login (sem API Key de device)."""
        return {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

    def _device_headers(self) -> dict[str, str]:
        """Headers para endpoints autenticados por device (RequireDeviceAuth
        no ERP): hoje só os proxies de consentimentos LGPD.
        """
        headers = self._headers()
        if self.api_key:
            headers["X-API-Key"] = self.api_key
        return headers

    def _is_configured(self) -> bool:
        return bool(self.base_url)

    async def get_attendance_config(self) -> dict[str, Any]:
        """Consulta a configuração de métodos de assiduidade (rh.assiduidade)
        do tenant do device autenticado.

        `GET /api/hardware/assiduidade/config` no Nexora ERP. Devolve
        `{"tenant_id": ..., "configuracao": {...}}`. Uso interno apenas —
        `attendance_validation.validar_metodo_assiduidade` usa isto para
        decidir se um método biométrico (facial/selfie) está activo para o
        tenant antes de o processar localmente; não há endpoint HTTP exposto
        para isto desde 2026-07-13 (a app deixou de precisar, não tem ecrã
        que leia esta config — ver AssiduidadeApiService.kt).
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/hardware/assiduidade/config",
                    headers=self._device_headers(),
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        # Um status de erro aqui é indistinguível de "ERP indisponível" para
        # quem chama: esta config é uma política opcional, não uma autorização.
        # Sem esta conversão, o httpx.HTTPStatusError escapava ao fail-open de
        # validar_metodo_assiduidade e /biometric/verify e /liveness/verify
        # respondiam 500 — foi o que aconteceu ao configurar ERP_BASE_URL sem
        # uma ERP_API_KEY registada em hardware.devices (o ERP devolve 401).
        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise ERPUnavailableError(
                f"ERP respondeu {response.status_code} a /api/hardware/assiduidade/config"
            ) from exc

        return response.json()

    def _raise_for_proxy(self, response: httpx.Response) -> None:
        if response.status_code >= 400:
            try:
                detail = response.json().get("error") or response.text
            except ValueError:
                detail = response.text
            raise ERPResponseError(response.status_code, detail)

    async def validar_consentimento_ativo(self, erp_user_id: str) -> dict[str, Any]:
        """Consulta consentimento LGPD ativo de um funcionário no ERP.

        `GET /api/hardware/assiduidade/consentimentos/activo?erp_user_id=...`
        Levanta ERPResponseError(404) se não houver consentimento ativo.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        headers = self._device_headers()
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/hardware/assiduidade/consentimentos/activo",
                    headers=headers,
                    params={"erp_user_id": erp_user_id},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        self._raise_for_proxy(response)
        return response.json()

    async def list_audit_logs(
        self,
        modulo: str | None = None,
        user_id: str | None = None,
        entidade: str | None = None,
        entidade_id: str | None = None,
        acao: str | None = None,
        page: int | None = None,
        limit: int | None = None,
    ) -> dict[str, Any]:
        """Proxy para `GET /api/audit-logs` no Nexora ERP.

        Usa a API Key de device configurada em ERP_API_KEY. O próprio ERP
        impõe `auditoria:ver_logs` via `RequirePermission`.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        headers = self._device_headers()
        params = {
            k: v
            for k, v in {
                "modulo": modulo,
                "user_id": user_id,
                "entidade": entidade,
                "entidade_id": entidade_id,
                "acao": acao,
                "page": page,
                "limit": limit,
            }.items()
            if v is not None
        }
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/audit-logs",
                    headers=headers,
                    params=params,
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        self._raise_for_proxy(response)
        return response.json()

    async def notify_reenroll_required(
        self,
        erp_user_id: str,
        tenant_id: str | None,
        old_model_version: str,
        new_model_version: str,
    ) -> None:
        """Notifica o ERP (best-effort) de que um utilizador precisa de
        re-enrolamento por mudanca de model_version.

        Nunca levanta excecao: se ERP_REENROLL_WEBHOOK_URL nao estiver
        configurado, ou o pedido falhar, apenas regista um aviso. O verify
        que despoletou isto ja marcou o template como PENDING_REENROLL — esta
        notificacao e so uma conveniencia operacional, nao uma dependencia
        critica do fluxo.
        """
        webhook_url = settings.erp_reenroll_webhook_url
        if not webhook_url:
            return
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                await client.post(
                    webhook_url,
                    headers=self._device_headers(),
                    json={
                        "erp_user_id": erp_user_id,
                        "tenant_id": tenant_id,
                        "old_model_version": old_model_version,
                        "new_model_version": new_model_version,
                    },
                )
        except httpx.RequestError as exc:
            log.warning(
                "Falha ao notificar ERP de re-enrolamento (erp_user_id=%s): %s", erp_user_id, exc
            )


erp_client = ERPClient()
