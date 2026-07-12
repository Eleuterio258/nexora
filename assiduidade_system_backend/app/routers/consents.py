from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import FaceTemplate, FingerprintTemplate
from app.schemas.common import TemplateStatus
from app.utils import utc_now


router = APIRouter(tags=["Consents"])


@router.post("/consents", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def create_consent() -> None:
    """PROXY ERP: persistência de consentimentos foi movida para o Nexora ERP.

    Implementar após criação de POST /api/lgpd/consents no ERP (Fase 6).
    """
    raise HTTPException(
        status_code=501,
        detail="Consentimentos LGPD são persistidos no Nexora ERP. Endpoint em construcao.",
    )


@router.get("/consents/users/{user_id}/active", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def get_active_consent() -> None:
    """PROXY ERP: consulta de consentimentos foi movida para o Nexora ERP."""
    raise HTTPException(
        status_code=501,
        detail="Consentimentos LGPD são consultados no Nexora ERP. Endpoint em construcao.",
    )


@router.post(
    "/consents/users/{user_id}/revoke",
    status_code=status.HTTP_200_OK,
)
def revoke_consent(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> dict:
    """Revogação de consentimento: desactiva templates biométricos locais.

    A persistência da revogação em si (consentimento LGPD) deve ser enviada
    para o Nexora ERP. Este endpoint mantém apenas o efeito local nos templates.
    """
    erp_user_id = user_id

    revoked_templates = db.scalars(
        apply_tenant(
            select(FaceTemplate).where(
                FaceTemplate.erp_user_id == erp_user_id,
                FaceTemplate.status == TemplateStatus.ACTIVE,
            ),
            actor,
            FaceTemplate,
        )
    )
    count = 0
    for template in revoked_templates:
        template.status = TemplateStatus.REVOKED
        template.revoked_at = utc_now()
        count += 1

    db.commit()

    # TODO: notificar ERP sobre revogação (Fase 6)

    return {
        "success": True,
        "message": f"{count} template(s) facial(is) desactivado(s). Revogacao no ERP pendente.",
    }


@router.delete(
    "/consents/users/{user_id}/biometric-data",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_biometric_data(
    user_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> None:
    """Remove dados biométricos locais (direito ao esquecimento LGPD).

    Apaga templates faciais e de impressão digital do FaceClock.
    O consentimento propriamente dito é gerido no ERP.
    """
    erp_user_id = user_id

    face_templates = db.scalars(
        apply_tenant(
            select(FaceTemplate).where(FaceTemplate.erp_user_id == erp_user_id),
            actor,
            FaceTemplate,
        )
    )
    fingerprint_templates = db.scalars(
        apply_tenant(
            select(FingerprintTemplate).where(FingerprintTemplate.erp_user_id == erp_user_id),
            actor,
            FingerprintTemplate,
        )
    )

    for template in face_templates:
        db.delete(template)
    for template in fingerprint_templates:
        db.delete(template)

    db.commit()

    # TODO: notificar ERP sobre exercício do direito ao esquecimento (Fase 6)


@router.get("/consents/users/{user_id}/history", status_code=status.HTTP_501_NOT_IMPLEMENTED)
def list_consent_history() -> None:
    """PROXY ERP: histórico de consentimentos foi movido para o Nexora ERP."""
    raise HTTPException(
        status_code=501,
        detail="Historico de consentimentos é consultado no Nexora ERP. Endpoint em construcao.",
    )
