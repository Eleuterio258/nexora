"""
Router para impressão digital (1:N real).

ATENCAO: A API BiometricPrompt do Android NAO devolve a imagem ou template da
impressão digital. Para identificação 1:N real é necessário um leitor de
impressão digital externo (USB/OTG) com SDK do fabricante.

Este router define a estrutura de dados e endpoints para quando esse hardware
estiver disponível. Até la, o metodo FINGERPRINT na app Android continua a usar
BiometricPrompt apenas como prova de presença vinculada ao utilizador autenticado.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.models import FingerprintTemplate, User

router = APIRouter(tags=["Fingerprint"])


class FingerprintEnrollRequest(BaseModel):
    user_id: str
    finger_type: str = "right_thumb"
    template_base64: str


class FingerprintVerifyRequest(BaseModel):
    template_base64: str


class FingerprintResponse(BaseModel):
    success: bool
    user_id: str | None = None
    message: str


@router.post("/fingerprint/enroll", response_model=FingerprintResponse)
def enroll_fingerprint(
    request: FingerprintEnrollRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> FingerprintResponse:
    """Regista um template de impressão digital para um utilizador."""
    user = db.scalar(
        apply_tenant(select(User).where(User.id == request.user_id), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Utilizador nao encontrado.")

    existing = db.scalar(
        apply_tenant(
            select(FingerprintTemplate).where(
                FingerprintTemplate.user_id == request.user_id,
                FingerprintTemplate.finger_type == request.finger_type,
            ),
            actor,
            FingerprintTemplate,
        )
    )
    if existing:
        existing.template_base64 = request.template_base64
    else:
        db.add(
            FingerprintTemplate(
                tenant_id=actor.tenant_id,
                user_id=request.user_id,
                finger_type=request.finger_type,
                template_base64=request.template_base64,
            )
        )
    db.commit()

    return FingerprintResponse(
        success=True,
        user_id=request.user_id,
        message="Template de impressão digital registado.",
    )


@router.post("/fingerprint/identify", response_model=FingerprintResponse)
def identify_fingerprint(
    request: FingerprintVerifyRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> FingerprintResponse:
    """
    Identifica um utilizador a partir de um template de impressão digital.

    Nota: Esta implementacao compara templates de forma exacta (placeholder).
    Em producao, deve usar um algoritmo de matching de minutias (ISO/IEC 19794-2)
    fornecido pelo SDK do leitor.
    """
    templates = db.scalars(
        apply_tenant(select(FingerprintTemplate), actor, FingerprintTemplate)
    ).all()

    for template in templates:
        if template.template_base64 == request.template_base64:
            return FingerprintResponse(
                success=True,
                user_id=template.user_id,
                message="Impressão digital identificada.",
            )

    return FingerprintResponse(
        success=False,
        message="Impressão digital nao identificada.",
    )


@router.delete("/fingerprint/enroll/{user_id}")
def delete_fingerprint_enrollment(
    user_id: str,
    finger_type: str | None = None,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> dict:
    """Remove o enrolamento de impressão digital de um utilizador."""
    stmt = apply_tenant(
        select(FingerprintTemplate).where(FingerprintTemplate.user_id == user_id),
        actor,
        FingerprintTemplate,
    )
    if finger_type:
        stmt = stmt.where(FingerprintTemplate.finger_type == finger_type)

    templates = db.scalars(stmt).all()
    if not templates:
        raise HTTPException(status_code=404, detail="Enrolamento nao encontrado.")

    for template in templates:
        db.delete(template)
    db.commit()

    return {"success": True, "message": f"{len(templates)} template(s) removido(s)."}
