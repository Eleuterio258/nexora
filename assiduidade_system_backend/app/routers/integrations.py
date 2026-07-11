import asyncio
import logging
import os
from datetime import datetime, timezone

import httpx
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import IntegrationBatchModel
from app.schemas.requests import PayrollPushRequest
from app.schemas.responses import BatchListResponse, BatchSummary, PayrollPushResponse


logger = logging.getLogger("faceclock.integrations")


router = APIRouter(tags=["Integrations"])


@router.get("/admin/integration-batches", response_model=BatchListResponse)
def list_batches(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    status_filter: str | None = Query(None),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> BatchListResponse:
    query = apply_tenant(select(IntegrationBatchModel), actor, IntegrationBatchModel)
    count_query = apply_tenant(
        select(func.count()).select_from(IntegrationBatchModel), actor, IntegrationBatchModel
    )
    if status_filter:
        query = query.where(IntegrationBatchModel.status == status_filter)
        count_query = count_query.where(IntegrationBatchModel.status == status_filter)

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(IntegrationBatchModel.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return BatchListResponse(
        items=[
            BatchSummary(
                id=row.id,
                provider_name=row.provider_name,
                status=row.status,
                total_records=row.total_records,
                accepted_records=row.accepted_records,
                rejected_records=row.rejected_records,
                created_at=row.created_at,
                finished_at=row.finished_at,
            )
            for row in rows
        ],
        page=page,
        page_size=page_size,
        total=total,
    )


async def push_to_external_provider(
    provider_name: str,
    records: list[dict],
) -> dict:
    """
    Envia registros para sistema externo de folha de pagamento.
    Usa configuracao por ambiente para determinar endpoint.
    """
    base_url = os.getenv("PAYROLL_PROVIDER_BASE_URL", "")
    if not base_url:
        return {"status": "simulated", "message": "No external provider configured, records stored locally"}

    endpoint = f"{base_url.rstrip('/')}/api/v1/clock-records/batch"
    api_key = os.getenv("PAYROLL_PROVIDER_API_KEY", "")
    timeout = int(os.getenv("PAYROLL_PROVIDER_TIMEOUT_SECONDS", "30"))

    payload = {
        "provider": provider_name,
        "records": records,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    max_retries = 2
    last_error = None

    for attempt in range(max_retries + 1):
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, json=payload, headers=headers)

                if response.status_code in (200, 201, 202):
                    result = response.json() if response.content else {}
                    return {
                        "status": "success",
                        "external_response": result,
                        "http_status": response.status_code,
                    }
                elif response.status_code == 429:
                    if attempt < max_retries:
                        await asyncio.sleep(2 ** attempt)
                        continue
                    return {"status": "rate_limited", "http_status": 429}
                else:
                    last_error = f"HTTP {response.status_code}: {response.text}"
                    if attempt < max_retries:
                        await asyncio.sleep(1)
                        continue
                    break
        except httpx.TimeoutException:
            last_error = "timeout"
            if attempt < max_retries:
                await asyncio.sleep(2 ** attempt)
                continue
        except httpx.ConnectError:
            last_error = "connection_failed"
            break
        except Exception as exc:
            last_error = str(exc)
            break

    return {"status": "failed", "error": last_error}


@router.post(
    "/integrations/payroll/push",
    response_model=PayrollPushResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def push_payroll(
    payload: PayrollPushRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PayrollPushResponse:
    records_data = [record.model_dump(mode="json") for record in payload.records]

    result = await push_to_external_provider(payload.provider_name, records_data)

    accepted = 0
    rejected = 0
    status_str = result.get("status", "failed")

    if status_str == "success":
        external = result.get("external_response", {})
        accepted = external.get("accepted", len(records_data))
        rejected = external.get("rejected", 0)
    elif status_str == "simulated":
        accepted = len(records_data)
        rejected = 0
    else:
        rejected = len(records_data)

    batch = IntegrationBatchModel(
        tenant_id=actor.tenant_id,
        provider_name=payload.provider_name,
        requested_by=actor.id or "unknown",
        status=status_str,
        total_records=len(records_data),
        accepted_records=accepted,
        rejected_records=rejected,
        request_payload=payload.model_dump(mode="json"),
        response_payload=result,
        finished_at=datetime.now(timezone.utc),
    )
    db.add(batch)
    db.commit()
    db.refresh(batch)

    logger.info(
        "Payroll push completed: provider=%s, tenant_id=%s, total=%d, accepted=%d, rejected=%d, status=%s",
        payload.provider_name,
        actor.tenant_id,
        len(records_data),
        accepted,
        rejected,
        status_str,
    )

    return PayrollPushResponse(
        batch_id=batch.id,
        accepted_records=batch.accepted_records,
        rejected_records=batch.rejected_records,
        status=batch.status,
    )
