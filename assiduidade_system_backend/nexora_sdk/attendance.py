"""Cliente para endpoints de assiduidade."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from .client import NexoraClient


class AttendanceClient:
    """Operações de assiduidade (registos de ponto).

    Nota: os endpoints /api/attendance/* ainda não estão implementados no
    FaceClock. Esta classe serve como ponto de extensão futuro.
    """

    def __init__(self, client: NexoraClient) -> None:
        self._client = client

    def create(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Cria um registo de assiduidade."""
        return self._client._request("POST", "/api/v1/attendance/create", payload=payload)

    def list(self, **params: Any) -> dict[str, Any]:
        """Lista registos de assiduidade."""
        from urllib.parse import urlencode

        query = urlencode(params)
        return self._client._request("GET", "/api/v1/attendance/list", query=query)
