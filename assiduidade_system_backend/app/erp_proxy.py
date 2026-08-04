"""Helpers partilhados pelos routers que são proxies finos para o Nexora ERP."""

from typing import Any, Awaitable, Callable

from fastapi import HTTPException, status

from app.erp_client import ERPResponseError, ERPUnavailableError


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
