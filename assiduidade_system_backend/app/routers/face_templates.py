"""Endpoints para gestao de templates biometricos."""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AuditLogModel, FaceTemplate, User
from app.schemas.common import TemplateStatus
from app.schemas.responses import ORMBaseModel


class FaceTemplateSummary(ORMBaseModel):
    id: UUID
    user_id: UUID
    model_version: str
    quality_score: float | None = None
    status: TemplateStatus
    created_at: str


router = APIRouter(tags=["Biometric Templates"])


@router.get("/admin/face-templates/users/{user_id}")
def list_user_templates(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> list[FaceTemplateSummary]:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    templates = db.scalars(
        apply_tenant(
            select(FaceTemplate).where(FaceTemplate.user_id == user_id)
            .order_by(FaceTemplate.created_at.desc()),
            actor,
            FaceTemplate,
        )
    ).all()
    return [FaceTemplateSummary.model_validate(t) for t in templates]


@router.delete("/admin/face-templates/{template_id}", status_code=204)
def revoke_template(
    template_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> None:
    template = db.scalar(
        apply_tenant(
            select(FaceTemplate).where(FaceTemplate.id == template_id),
            actor,
            FaceTemplate,
        )
    )
    if not template:
        raise HTTPException(status_code=404, detail="Template nao encontrado.")
    template.status = TemplateStatus.REVOKED
    from app.utils import utc_now
    template.revoked_at = utc_now()
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or "unknown",
            action="TEMPLATE_REVOKE",
            entity_type="face_template",
            entity_id=template.id,
            payload_hash=f"revoked:{template.id}",
            previous_hash=chain_audit_hash(db, f"revoked:{template.id}"),
        )
    )
    db.commit()
