"""Cliente principal do SDK Nexora."""

from typing import Any

import httpx

from .attendance import AttendanceClient
from .biometric import BiometricClient
from .credentials import Credentials, resolve_credentials
from .exceptions import NexoraRequestError
from .signer import serialize_body, sign_request


class NexoraClient:
    """Cliente Python para integração com a API Nexora/FaceClock.

    As credenciais são resolvidas nesta ordem:
      1. Parâmetros passados ao construtor.
      2. Variáveis de ambiente.
      3. Ficheiro de configuração Nexora.
    """

    def __init__(
        self,
        access_key_id: str | None = None,
        secret_access_key: str | None = None,
        base_url: str | None = None,
        auth_version: str = "NEXORA-HMAC-SHA256-V1",
        timeout: float = 30.0,
    ) -> None:
        self.credentials = resolve_credentials(
            access_key_id=access_key_id,
            secret_access_key=secret_access_key,
            base_url=base_url,
        )
        self.auth_version = auth_version
        self.timeout = timeout
        self.biometric = BiometricClient(self)
        self.attendance = AttendanceClient(self)

    def _signed_headers(
        self,
        method: str,
        path: str,
        query: str = "",
        payload: Any = None,
    ) -> dict[str, str]:
        """Devolve os headers assinados para um pedido."""
        return sign_request(
            access_key_id=self.credentials.access_key_id,
            secret_access_key=self.credentials.secret_access_key,
            method=method,
            path=path,
            query=query,
            payload=payload,
            auth_version=self.auth_version,
        )

    def _request(
        self,
        method: str,
        path: str,
        query: str = "",
        payload: Any = None,
    ) -> Any:
        """Envia um pedido assinado para o backend e devolve a resposta JSON."""
        url = f"{self.credentials.base_url}{path}"
        if query:
            url = f"{url}?{query}"

        headers = self._signed_headers(method, path, query, payload)

        body = serialize_body(payload) if payload is not None else None

        with httpx.Client(timeout=self.timeout) as client:
            response = client.request(
                method=method,
                url=url,
                headers=headers,
                content=body,
            )

        if response.status_code >= 400:
            raise NexoraRequestError(
                f"Pedido Nexora falhou: {response.status_code}",
                status_code=response.status_code,
                response_body=response.text,
            )

        if response.status_code == 204 or not response.content:
            return None

        return response.json()

    def request(self, method: str, path: str, **kwargs: Any) -> Any:
        """Método de baixo nível para chamadas genéricas."""
        return self._request(
            method=method,
            path=path,
            query=kwargs.get("query", ""),
            payload=kwargs.get("payload"),
        )
