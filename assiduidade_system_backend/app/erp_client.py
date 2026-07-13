"""
Cliente HTTP para integração com o Nexora ERP.

Desde 2026-07-13, os endpoints autenticados por API Key de device
(funcionários, config de assiduidade, eventos de presença, QR/NFC/geofence)
deixaram de passar por aqui — a app Android chama-os directamente no ERP com
a chave embutida no APK (ver ErpApiService.kt/HardwareEventMapper.kt no
nexora_assiduidade). Este cliente mantém-se para:
- Validar o Bearer token de um utilizador já autenticado no ERP (delega em
  GET /api/auth/gateway/validate — o login em si é feito directamente no
  ERP, ver Fase 6 da integração).
- Proxies de consentimentos LGPD (ainda autenticados por API Key de device,
  porque são submetidos no momento do enrolamento biométrico, antes de haver
  sessão do próprio colaborador).
- Proxies Bearer-autenticados (audit-logs, cancelamento de correcção de ponto).

Quando o ERP não está configurado ou está indisponível, as operações
levantam ERPUnavailableError para que o chamador possa decidir sobre fallback.
"""

from typing import Any

import httpx

from app.config import settings


class ERPUnavailableError(Exception):
    """ERP não responde ou não está configurado."""


class ERPAuthError(Exception):
    """Credenciais inválidas no ERP."""


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

        response.raise_for_status()
        return response.json()

    async def validate_bearer_token(self, token: str) -> dict[str, Any]:
        """Valida o Bearer token de um utilizador (não API Key de device) junto
        do Nexora ERP, delegando a resolução de identidade em vez de decifrar o
        token localmente — o FaceClock não partilha segredo de assinatura com o
        ERP, por isso não pode validar um JWT do ERP sozinho.

        Chama `GET /api/auth/gateway/validate`, reencaminhando o MESMO token do
        utilizador (`Authorization: Bearer <token>`) — ao contrário dos outros
        métodos deste cliente, que usam a API Key de device
        (`_device_headers()`). O ERP já valida o token com o seu próprio JWT
        middleware antes de chegar ao handler (ver
        `backend/internal/router/router.go`, grupo `RequireAuth` em
        `/api/auth`), e devolve a identidade via headers `X-Auth-*` (incluindo
        `X-Auth-User-Role`, já traduzido para o vocabulário do FaceClock —
        `ADMIN_SISTEMA`/`GESTOR_RH`/`COLABORADOR` — ver
        `GatewayValidate`/`gatewayAppRole` em
        `backend/internal/modules/auth/handlers/auth.go`).
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/auth/gateway/validate",
                    headers={
                        **self._headers(), "Authorization": f"Bearer {token}"},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        if response.status_code in (401, 403):
            raise ERPAuthError("Token invalido ou expirado no ERP.")
        response.raise_for_status()

        headers = response.headers
        return {
            "id": headers.get("X-Auth-User-Id"),
            "role": headers.get("X-Auth-User-Role"),
            "tenant_id": headers.get("X-Auth-Tenant-Id"),
        }

    def _raise_for_proxy(self, response: httpx.Response) -> None:
        if response.status_code >= 400:
            try:
                detail = response.json().get("error") or response.text
            except ValueError:
                detail = response.text
            raise ERPResponseError(response.status_code, detail)

    async def list_audit_logs(
        self,
        authorization: str,
        modulo: str | None = None,
        user_id: str | None = None,
        entidade: str | None = None,
        entidade_id: str | None = None,
        acao: str | None = None,
        page: int | None = None,
        limit: int | None = None,
    ) -> dict[str, Any]:
        """Proxy para `GET /api/audit-logs` no Nexora ERP. Reencaminha o Bearer
        token de quem chama — o próprio ERP impõe `auditoria:ver_logs` via
        `RequirePermission`, por isso não há verificação de papel adicional no
        FaceClock (para não haver duas fontes de verdade sobre quem pode ver
        auditoria).
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        headers = {**self._headers(), "Authorization": authorization}
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

erp_client = ERPClient()
