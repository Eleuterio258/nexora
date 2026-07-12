"""
Router para códigos de autenticação auxiliares: PIN e TOTP.

No modelo stateless, PIN e TOTP são geridos e validados pelo Nexora ERP
(`/api/authcode/*`, ver `backend/internal/modules/auth/handlers/authcode.go`).
Este router é um proxy fino: reencaminha o pedido/token para o ERP e devolve
a mesma resposta, sem persistir nem validar nada localmente.
"""

from typing import Any

from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field

from app.erp_client import ERPResponseError, ERPUnavailableError, erp_client

router = APIRouter(tags=["Auth Code"])


class PinValidateRequest(BaseModel):
    email: str = Field(..., min_length=1)
    pin: str = Field(..., min_length=1)


class TotpValidateRequest(BaseModel):
    email: str = Field(..., min_length=1)
    code: str = Field(..., min_length=1)


class TotpSetupRequest(BaseModel):
    password: str | None = None


class AdminSetPinRequest(BaseModel):
    user_id: int
    pin: str = Field(..., min_length=6)


def _require_authorization(authorization: str | None) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization: Bearer <token> obrigatorio.",
        )
    return authorization


async def _proxy_erp_call(call) -> Any:
    try:
        return await call()
    except ERPUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"ERP indisponivel: {exc}",
        ) from exc
    except ERPResponseError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.detail) from exc


@router.post("/authcode/pin/validate")
async def validate_pin(payload: PinValidateRequest) -> dict[str, Any]:
    """Login alternativo por PIN, delegado no Nexora ERP."""
    return await _proxy_erp_call(
        lambda: erp_client.authcode_pin_validate(payload.email, payload.pin)
    )


@router.post("/authcode/totp/validate")
async def validate_totp(payload: TotpValidateRequest) -> dict[str, Any]:
    """Login alternativo por código TOTP, delegado no Nexora ERP."""
    return await _proxy_erp_call(
        lambda: erp_client.authcode_totp_validate(payload.email, payload.code)
    )


@router.post("/authcode/totp/setup")
async def setup_totp(
    payload: TotpSetupRequest,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> dict[str, Any]:
    """Configura TOTP para o utilizador autenticado, delegado no Nexora ERP."""
    token = _require_authorization(authorization)
    return await _proxy_erp_call(
        lambda: erp_client.authcode_totp_setup(token, payload.password)
    )


@router.post("/authcode/admin/set-pin", status_code=status.HTTP_204_NO_CONTENT)
async def admin_set_pin(
    payload: AdminSetPinRequest,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> None:
    """Define o PIN de outro utilizador. O Nexora ERP valida a permissão
    `auth:pin_admin` de quem chama — este router só reencaminha o pedido."""
    token = _require_authorization(authorization)
    await _proxy_erp_call(
        lambda: erp_client.authcode_admin_set_pin(token, payload.user_id, payload.pin)
    )
