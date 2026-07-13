"""
Helpers partilhados pelos routers que são proxies finos para o Nexora ERP
(reencaminham o Bearer token do chamador e traduzem erros do ERP para
HTTPException) — usados por `clock.py`, `consents.py`, `methods.py` e
`audit.py`.
"""

from typing import Any, Awaitable, Callable

from fastapi import HTTPException, status

from app.erp_client import ERPResponseError, ERPUnavailableError


def require_authorization(authorization: str | None) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization: Bearer <token> obrigatorio.",
        )
    return authorization


async def call_erp(call: Callable[[], Awaitable[Any]]) -> Any:
    try:
        return await call()
    except ERPUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"ERP indisponivel: {exc}",
        ) from exc
    except ERPResponseError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.detail) from exc
