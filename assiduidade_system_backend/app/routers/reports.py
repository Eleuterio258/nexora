"""
Router de relatórios de assiduidade.

Fornece resumos diários, relatórios por colaborador e sumários por período,
baseados nos registos de ponto (`clock_records`).
"""

from datetime import date, datetime, time, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import ClockRecordModel, User
from app.schemas.common import EventType

router = APIRouter(tags=["Reports"])


class DailyReportItem(BaseModel):
    user_id: str
    full_name: str
    date: date
    first_entry: datetime | None
    last_exit: datetime | None
    entries: int
    exits: int
    worked_hours: float | None


class EmployeeReportItem(BaseModel):
    id: str
    event_type: str
    recorded_at: datetime
    source: str
    sync_status: str


class SummaryReportResponse(BaseModel):
    total_users: int
    total_events: int
    entries: int
    exits: int
    start_date: date
    end_date: date


class DailyReportResponse(BaseModel):
    date: date
    items: list[DailyReportItem]


class EmployeeReportResponse(BaseModel):
    user_id: str
    full_name: str
    start_date: date
    end_date: date
    items: list[EmployeeReportItem]


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


@router.get("/reports/daily", response_model=DailyReportResponse)
def daily_report(
    report_date: date | None = Query(None, description="Data do relatório (default: hoje)"),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> DailyReportResponse:
    """Relatório diário de entradas e saídas por colaborador."""
    target_date = report_date or date.today()
    start_dt = datetime.combine(target_date, time.min)
    end_dt = datetime.combine(target_date, time.max)

    rows = db.scalars(
        apply_tenant(
            select(ClockRecordModel)
            .where(ClockRecordModel.recorded_at >= start_dt)
            .where(ClockRecordModel.recorded_at <= end_dt)
            .order_by(ClockRecordModel.recorded_at.asc()),
            actor,
            ClockRecordModel,
        )
    ).all()

    user_ids = {row.user_id for row in rows}
    users = {
        str(u.id): u.full_name
        for u in db.scalars(
            apply_tenant(select(User).where(User.id.in_(user_ids)), actor, User)
        ).all()
    }

    by_user: dict[str, dict[str, Any]] = {}
    for row in rows:
        uid = row.user_id
        if uid not in by_user:
            by_user[uid] = {
                "entries": [],
                "exits": [],
            }
        if row.event_type == EventType.ENTRY:
            by_user[uid]["entries"].append(row.recorded_at)
        elif row.event_type == EventType.EXIT:
            by_user[uid]["exits"].append(row.recorded_at)

    items: list[DailyReportItem] = []
    for uid, data in by_user.items():
        entries = sorted(data["entries"])
        exits = sorted(data["exits"])
        first_entry = entries[0] if entries else None
        last_exit = exits[-1] if exits else None

        worked_hours = None
        if first_entry and last_exit and last_exit > first_entry:
            delta = _ensure_utc(last_exit) - _ensure_utc(first_entry)
            worked_hours = round(delta.total_seconds() / 3600, 2)

        items.append(
            DailyReportItem(
                user_id=uid,
                full_name=users.get(uid, "Desconhecido"),
                date=target_date,
                first_entry=first_entry,
                last_exit=last_exit,
                entries=len(entries),
                exits=len(exits),
                worked_hours=worked_hours,
            )
        )

    return DailyReportResponse(date=target_date, items=items)


@router.get("/reports/employee/{user_id}", response_model=EmployeeReportResponse)
def employee_report(
    user_id: str,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> EmployeeReportResponse:
    """Relatório de presença de um colaborador num período."""
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Utilizador nao encontrado.")

    end = end_date or date.today()
    start = start_date or end

    start_dt = datetime.combine(start, time.min)
    end_dt = datetime.combine(end, time.max)

    rows = db.scalars(
        apply_tenant(
            select(ClockRecordModel)
            .where(ClockRecordModel.user_id == user_id)
            .where(ClockRecordModel.recorded_at >= start_dt)
            .where(ClockRecordModel.recorded_at <= end_dt)
            .order_by(ClockRecordModel.recorded_at.desc()),
            actor,
            ClockRecordModel,
        )
    ).all()

    items = [
        EmployeeReportItem(
            id=row.id,
            event_type=row.event_type.value,
            recorded_at=row.recorded_at,
            source=row.source.value,
            sync_status=row.sync_status.value,
        )
        for row in rows
    ]

    return EmployeeReportResponse(
        user_id=user_id,
        full_name=user.full_name,
        start_date=start,
        end_date=end,
        items=items,
    )


@router.get("/reports/summary", response_model=SummaryReportResponse)
def summary_report(
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> SummaryReportResponse:
    """Sumário de eventos de presença no período."""
    end = end_date or date.today()
    start = start_date or end

    start_dt = datetime.combine(start, time.min)
    end_dt = datetime.combine(end, time.max)

    total_users = db.scalar(
        apply_tenant(select(func.count(User.id)), actor, User)
    ) or 0

    base_events = apply_tenant(
        select(func.count(ClockRecordModel.id)).where(
            ClockRecordModel.recorded_at >= start_dt,
            ClockRecordModel.recorded_at <= end_dt,
        ),
        actor,
        ClockRecordModel,
    )
    total_events = db.scalar(base_events) or 0

    entries = (
        db.scalar(
            apply_tenant(
                select(func.count(ClockRecordModel.id)).where(
                    ClockRecordModel.recorded_at >= start_dt,
                    ClockRecordModel.recorded_at <= end_dt,
                    ClockRecordModel.event_type == EventType.ENTRY,
                ),
                actor,
                ClockRecordModel,
            )
        )
        or 0
    )
    exits = (
        db.scalar(
            apply_tenant(
                select(func.count(ClockRecordModel.id)).where(
                    ClockRecordModel.recorded_at >= start_dt,
                    ClockRecordModel.recorded_at <= end_dt,
                    ClockRecordModel.event_type == EventType.EXIT,
                ),
                actor,
                ClockRecordModel,
            )
        )
        or 0
    )

    return SummaryReportResponse(
        total_users=total_users,
        total_events=total_events,
        entries=entries,
        exits=exits,
        start_date=start,
        end_date=end,
    )
