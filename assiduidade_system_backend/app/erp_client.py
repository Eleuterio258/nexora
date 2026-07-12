"""
Cliente HTTP para integração com o Nexora ERP.

Permite:
- Validar o Bearer token de um utilizador já autenticado no ERP (delega em
  GET /api/auth/gateway/validate — o login em si passou a ser feito
  directamente no ERP, ver Fase 6 da integração).
- Listar/obter funcionários (via device API Key, não JWT de utilizador).
- Consultar a configuração de métodos de assiduidade (rh.assiduidade) por tenant.
- Enviar eventos de presença para o ERP (módulo hardware, device API Key).

Os endpoints de funcionários/config/eventos são autenticados com a MESMA
API Key de device (`erp_api_key`, enviada como `X-API-Key`), porque o FaceClock
está registado como um "device" em hardware.devices no ERP — ver
assiduidade_system_backend/CONTRATO-INTEGRACAO-ERP.md, secção 4.
`validate_bearer_token` não usa API Key: reencaminha o próprio JWT do
utilizador para o ERP validar.

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

    Usado pelos proxies de authcode, cujo contrato de erro (`{"error": "..."}`,
    vários status possíveis: 400/401/403/404) não se resume a "indisponível" ou
    "credenciais inválidas" — o FaceClock devolve o mesmo status/mensagem do ERP
    em vez de os achatar.
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
        no ERP): funcionários, config de assiduidade, eventos de presença.
        """
        headers = self._headers()
        if self.api_key:
            headers["X-API-Key"] = self.api_key
        return headers

    def _is_configured(self) -> bool:
        return bool(self.base_url)

    async def get_employees(self) -> list[dict[str, Any]]:
        """Lista todos os funcionários do tenant do device autenticado.

        Endpoint dedicado do Nexora ERP (não é `/api/hr/employees` genérico):
        `GET /api/hardware/assiduidade/funcionarios`, autenticado por API Key
        de device — o tenant é resolvido pelo próprio device no ERP, não é
        passado como parâmetro aqui.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/hardware/assiduidade/funcionarios",
                    headers=self._device_headers(),
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        response.raise_for_status()
        data = response.json()
        if isinstance(data, dict):
            return data.get("data", data.get("employees", data.get("items", [])))
        return list(data)

    async def get_employee(self, employee_id: str | int) -> dict[str, Any]:
        """Obtém detalhes de um funcionário específico do tenant do device autenticado."""
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/hardware/assiduidade/funcionarios/{employee_id}",
                    headers=self._device_headers(),
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        response.raise_for_status()
        return response.json()

    async def get_attendance_config(self) -> dict[str, Any]:
        """Consulta a configuração de métodos de assiduidade (rh.assiduidade)
        do tenant do device autenticado.

        `GET /api/hardware/assiduidade/config` no Nexora ERP. Devolve
        `{"tenant_id": ..., "configuracao": {...}}`. Levanta ERPUnavailableError
        se o ERP não responder, e propaga o `403`/`402` (feature inactiva) via
        `response.raise_for_status()` para o chamador decidir.
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

    async def send_attendance_event(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Envia um evento de presença para o ERP via módulo hardware
        (`POST /api/hardware/events/generic`), reaproveitando a ingestão de
        eventos de dispositivos já existente em vez de um endpoint dedicado
        — ver CONTRATO-INTEGRACAO-ERP.md, secção 3.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/hardware/events/generic",
                    headers=self._device_headers(),
                    json=payload,
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
                    headers={**self._headers(), "Authorization": f"Bearer {token}"},
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

    async def send_attendance_events_batch(self, events: list[dict[str, Any]]) -> dict[str, Any]:
        """Envia até 100 eventos de presença de uma vez ao ERP
        (`POST /api/hardware/events/batch`), para reenvio em lote de eventos
        pendentes/falhados em vez de N chamadas individuais — ver
        `docs/readme.md` (RF01, backlog offline) e CONTRATO-INTEGRACAO-ERP.md.

        Contrato diferente de `send_attendance_event`: este endpoint espera
        `{"events": [...]}` com o formato `models.NormalizedEvent` do ERP
        (campos em PascalCase, sem tags JSON custom — `DeviceSerial`,
        `EmployeeNo`, `EventType`, `EventTime`, `Direction`, `CredentialType`),
        não o `GenericPayload` em snake_case do envio individual. Devolve
        `{"total", "processed", "failed", "results": [...]}`, com um resultado
        por índice na mesma ordem do pedido.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        if not events:
            return {"total": 0, "processed": 0, "failed": 0, "results": []}
        if len(events) > 100:
            raise ValueError("Maximo de 100 eventos por lote (limite do ERP).")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/hardware/events/batch",
                    headers=self._device_headers(),
                    json={"events": events},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        response.raise_for_status()
        return response.json()

    def _raise_for_proxy(self, response: httpx.Response) -> None:
        if response.status_code >= 400:
            try:
                detail = response.json().get("error") or response.text
            except ValueError:
                detail = response.text
            raise ERPResponseError(response.status_code, detail)

    async def authcode_pin_validate(self, email: str, pin: str) -> dict[str, Any]:
        """Proxy para `POST /api/authcode/pin/validate` no Nexora ERP — login
        alternativo por PIN. Endpoint público do ERP (sem auth prévia), devolve
        os mesmos tokens que `/api/auth/login`.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/authcode/pin/validate",
                    headers=self._headers(),
                    json={"email": email, "pin": pin},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        self._raise_for_proxy(response)
        return response.json()

    async def authcode_totp_validate(self, email: str, code: str) -> dict[str, Any]:
        """Proxy para `POST /api/authcode/totp/validate` no Nexora ERP — login
        alternativo por código TOTP. Endpoint público do ERP, devolve os mesmos
        tokens que `/api/auth/login`.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/authcode/totp/validate",
                    headers=self._headers(),
                    json={"email": email, "code": code},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        self._raise_for_proxy(response)
        return response.json()

    async def authcode_totp_setup(self, authorization: str, password: str | None = None) -> dict[str, Any]:
        """Proxy para `POST /api/authcode/totp/setup` no Nexora ERP — gera o
        segredo TOTP do utilizador autenticado. Reencaminha o Bearer token do
        próprio utilizador (não API Key de device), tal como
        `validate_bearer_token`, porque o ERP identifica o utilizador pelo JWT.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        headers = {**self._headers(), "Authorization": authorization}
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/authcode/totp/setup",
                    headers=headers,
                    json={"password": password} if password else {},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        self._raise_for_proxy(response)
        return response.json()

    async def authcode_admin_set_pin(self, authorization: str, user_id: int, pin: str) -> None:
        """Proxy para `POST /api/authcode/admin/set-pin` no Nexora ERP — define o
        PIN de outro utilizador. Reencaminha o Bearer token de quem chama; o
        próprio ERP valida a permissão `auth:pin_admin` (não há verificação de
        papel adicional no FaceClock, para não haver duas fontes de verdade
        sobre quem pode administrar PINs).
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")
        headers = {**self._headers(), "Authorization": authorization}
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/authcode/admin/set-pin",
                    headers=headers,
                    json={"user_id": user_id, "pin": pin},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        self._raise_for_proxy(response)


erp_client = ERPClient()
