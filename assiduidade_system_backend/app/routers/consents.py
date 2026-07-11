from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import AuditLogModel, Consent, FaceTemplate, User
from app.schemas.common import TemplateStatus
from app.schemas.requests import ConsentCreateRequest
from app.schemas.responses import ConsentResponse, PaginatedConsents
from app.utils import utc_now


router = APIRouter(tags=["Consents"])


@router.post(
    "/consents",
    response_model=ConsentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_consent(
    payload: ConsentCreateRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> ConsentResponse:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == str(payload.user_id)), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    consent = Consent(
        tenant_id=actor.tenant_id,
        user_id=str(payload.user_id),
        term_version=payload.term_version,
        consent_hash=payload.consent_hash,
        accepted_at=payload.accepted_at,
        legal_basis=payload.legal_basis,
    )
    db.add(consent)
    db.flush()

    chained_hash = chain_audit_hash(db, payload.consent_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or str(payload.user_id),
            action="CONSENT_CREATE",
            entity_type="consent",
            entity_id=consent.id,
            payload_hash=payload.consent_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(consent)
    return ConsentResponse.model_validate(consent)


@router.get("/consents/users/{user_id}/active", response_model=ConsentResponse)
def get_active_consent(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> ConsentResponse:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    consent = db.scalar(
        apply_tenant(
            select(Consent)
            .where(Consent.user_id == user_id, Consent.revoked_at.is_(None))
            .order_by(Consent.accepted_at.desc()),
            actor,
            Consent,
        )
    )
    if not consent:
        raise HTTPException(status_code=404, detail="Consentimento ativo nao encontrado.")
    return ConsentResponse.model_validate(consent)


@router.post(
    "/consents/users/{user_id}/revoke",
    response_model=ConsentResponse,
    status_code=status.HTTP_200_OK,
)
def revoke_consent(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> ConsentResponse:
    """Revoga o consentimento ativo de um usuario.
    Ao revogar, todos os templates biometricos ativos sao desativados.
    O usuario nao podera mais realizar enrollment ou verificacao biometrica.
    """
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    consent = db.scalar(
        apply_tenant(
            select(Consent)
            .where(Consent.user_id == user_id, Consent.revoked_at.is_(None))
            .order_by(Consent.accepted_at.desc()),
            actor,
            Consent,
        )
    )
    if not consent:
        raise HTTPException(status_code=404, detail="Nenhum consentimento ativo encontrado.")

    consent.revoked_at = utc_now()

    revoked_templates = db.scalars(
        apply_tenant(
            select(FaceTemplate).where(
                FaceTemplate.user_id == user_id,
                FaceTemplate.status == TemplateStatus.ACTIVE,
            ),
            actor,
            FaceTemplate,
        )
    )
    for template in revoked_templates:
        template.status = TemplateStatus.REVOKED
        template.revoked_at = utc_now()

    db.flush()

    revoke_hash = f"revoked:{consent.consent_hash}"
    chained_hash = chain_audit_hash(db, revoke_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or user_id,
            action="CONSENT_REVOKE",
            entity_type="consent",
            entity_id=consent.id,
            payload_hash=revoke_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    db.refresh(consent)
    return ConsentResponse.model_validate(consent)


@router.delete(
    "/consents/users/{user_id}/biometric-data",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_biometric_data(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> None:
    """Remove dados biometricos sensiveis de um usuario (direito LGPD).
    Revoga consentimento, remove templates e registra na auditoria.
    Os registros de ponto sao mantidos por exigencia legal.
    """
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    consent = db.scalar(
        apply_tenant(
            select(Consent)
            .where(Consent.user_id == user_id, Consent.revoked_at.is_(None))
            .order_by(Consent.accepted_at.desc()),
            actor,
            Consent,
        )
    )
    if consent:
        consent.revoked_at = utc_now()

    templates = db.scalars(
        apply_tenant(
            select(FaceTemplate).where(FaceTemplate.user_id == user_id),
            actor,
            FaceTemplate,
        )
    )
    deleted_count = 0
    for template in templates:
        db.delete(template)
        deleted_count += 1

    db.flush()

    delete_hash = f"biometric_deleted:{user_id}:count={deleted_count}"
    chained_hash = chain_audit_hash(db, delete_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or user_id,
            action="BIOMETRIC_DATA_DELETE",
            entity_type="user",
            entity_id=user_id,
            payload_hash=delete_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()


@router.get("/consents/users/{user_id}/history", response_model=PaginatedConsents)
def list_consent_history(
    user_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> PaginatedConsents:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    query = apply_tenant(
        select(Consent).where(Consent.user_id == user_id),
        actor,
        Consent,
    )
    count_query = apply_tenant(
        select(func.count()).select_from(Consent).where(Consent.user_id == user_id),
        actor,
        Consent,
    )

    total = db.scalar(count_query) or 0
    rows = db.scalars(
        query.order_by(Consent.accepted_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return PaginatedConsents(
        items=[ConsentResponse.model_validate(r) for r in rows],
        page=page,
        page_size=page_size,
        total=total,
    )
