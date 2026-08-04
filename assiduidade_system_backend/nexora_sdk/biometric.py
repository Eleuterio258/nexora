"""Cliente para endpoints biométricos do FaceClock."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from .client import NexoraClient


class BiometricClient:
    """Operações biométricas: enroll e verify."""

    def __init__(self, client: NexoraClient) -> None:
        self._client = client

    def enroll(
        self,
        user_id: str,
        captures: list[dict[str, Any]],
    ) -> dict[str, Any]:
        """Regista templates biométricos para um utilizador.

        Args:
            user_id: identificador do utilizador no ERP.
            captures: lista de capturas, cada uma com image_base64 e/ou image_url.

        Returns:
            Resposta JSON do backend.
        """
        payload = {"user_id": user_id, "captures": captures}
        return self._client._request("POST", "/api/v1/biometric/enroll", payload=payload)

    def verify(
        self,
        user_id: str,
        image_base64: str | None = None,
        image_url: str | None = None,
        device_id: str | None = None,
        geo_lat: float | None = None,
        geo_lng: float | None = None,
    ) -> dict[str, Any]:
        """Verifica a identidade de um utilizador por reconhecimento facial.

        Args:
            user_id: identificador do utilizador no ERP.
            image_base64: imagem em base64 (alternativa a image_url).
            image_url: URL da imagem (alternativa a image_base64).
            device_id: identificador do dispositivo/terminal.
            geo_lat: latitude opcional.
            geo_lng: longitude opcional.

        Returns:
            Resposta JSON do backend.
        """
        payload: dict[str, Any] = {"user_id": user_id}
        if image_base64:
            payload["image_base64"] = image_base64
        if image_url:
            payload["image_url"] = image_url
        if device_id:
            payload["device_id"] = device_id
        if geo_lat is not None:
            payload["geo_lat"] = geo_lat
        if geo_lng is not None:
            payload["geo_lng"] = geo_lng

        return self._client._request("POST", "/api/v1/biometric/verify", payload=payload)
