"""
Cliente HTTP para integração com o Omnisys ERP.

Permite:
- Autenticar utilizadores no ERP.
- Listar/obter funcionários.
- Enviar eventos de presença para o ERP.

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


class ERPClient:
    def __init__(self) -> None:
        self.base_url = settings.erp_base_url.rstrip("/")
        self.api_key = settings.erp_api_key
        self.timeout = settings.erp_timeout_seconds

    def _headers(self) -> dict[str, str]:
        headers: dict[str, str] = {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        if self.api_key:
            headers["X-Integration-Key"] = self.api_key
        return headers

    def _is_configured(self) -> bool:
        return bool(self.base_url)

    async def authenticate_user(self, username: str, password: str) -> dict[str, Any]:
        """
        Autentica um utilizador no ERP Omnisys.
        Retorna dict com: user_id, tenant_id, role, full_name, email.
        """
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/auth/login",
                    headers=self._headers(),
                    json={"username": username, "password": password},
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        if response.status_code == 401:
            raise ERPAuthError("Credenciais invalidas no ERP.")
        response.raise_for_status()
        return response.json()

    async def get_employees(self) -> list[dict[str, Any]]:
        """Lista todos os funcionários ativos do ERP."""
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/hr/employees",
                    headers=self._headers(),
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        response.raise_for_status()
        data = response.json()
        if isinstance(data, dict):
            return data.get("data", data.get("employees", data.get("items", [])))
        return list(data)

    async def get_employee(self, employee_id: str | int) -> dict[str, Any]:
        """Obtém detalhes de um funcionário específico."""
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/api/hr/employees/{employee_id}",
                    headers=self._headers(),
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        response.raise_for_status()
        return response.json()

    async def send_attendance_event(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Envia um evento de presença para o ERP."""
        if not self._is_configured():
            raise ERPUnavailableError("ERP_BASE_URL nao configurado.")

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/hr/attendance/events",
                    headers=self._headers(),
                    json=payload,
                )
        except httpx.RequestError as exc:
            raise ERPUnavailableError(f"ERP indisponivel: {exc}") from exc

        response.raise_for_status()
        return response.json()


erp_client = ERPClient()
