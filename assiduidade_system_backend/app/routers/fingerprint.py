"""
Router para impressão digital (1:N real).

ATENCAO: A API BiometricPrompt do Android NAO devolve a imagem ou template da
impressão digital. Para identificação 1:N real é necessário um leitor de
impressão digital externo (USB/OTG) com SDK do fabricante.

Este router define a estrutura de dados e endpoints para quando esse hardware
estiver disponível. Até la, o metodo FINGERPRINT na app Android continua a usar
BiometricPrompt apenas como prova de presença vinculada ao utilizador autenticado.
"""

import base64

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, field_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import ActorContext, apply_tenant, require_self_or_manager
from app.security import require_nexora_signature
from app.limiter import limiter
from app.models import FingerprintTemplate
from app.security import get_biometric_encryption
from app.services.fingerprint_matching import best_fingerprint_match

router = APIRouter(tags=["Fingerprint"])


class FingerprintEnrollRequest(BaseModel):
    user_id: str
    erp_funcionario_id: str | None = None
    finger_type: str = "right_thumb"
    template_base64: str

    @field_validator("template_base64")
    @classmethod
    def _validate_base64(cls, value: str) -> str:
        try:
            base64.b64decode(value, validate=True)
        except Exception as exc:
            raise ValueError("template_base64 deve ser uma string base64 valida.") from exc
        return value


class FingerprintVerifyRequest(BaseModel):
    template_base64: str

    @field_validator("template_base64")
    @classmethod
    def _validate_base64(cls, value: str) -> str:
        try:
            base64.b64decode(value, validate=True)
        except Exception as exc:
            raise ValueError("template_base64 deve ser uma string base64 valida.") from exc
        return value


class FingerprintEnrollResponse(BaseModel):
    success: bool
    template_id: str | None = None
    user_id: str | None = None
    message: str


class FingerprintResponse(BaseModel):
    success: bool
    user_id: str | None = None
    message: str


@router.post(
    "/fingerprint/enroll",
    response_model=FingerprintEnrollResponse,
    status_code=status.HTTP_201_CREATED,
)
@limiter.limit("20/hour")
def enroll_fingerprint(
    request: Request,
    payload: FingerprintEnrollRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("fingerprint:enroll"),
) -> FingerprintEnrollResponse:
    """Regista ou actualiza um template de impressão digital para um utilizador."""
    erp_user_id = payload.user_id
    require_self_or_manager(actor, erp_user_id)

    existing = db.scalar(
        apply_tenant(
            select(FingerprintTemplate).where(
                FingerprintTemplate.erp_user_id == erp_user_id,
                FingerprintTemplate.finger_type == payload.finger_type,
            ),
            actor,
            FingerprintTemplate,
        )
    )
    encryption = get_biometric_encryption()
    encrypted_template = encryption.encrypt_text(payload.template_base64)

    if existing:
        existing.template_base64 = encrypted_template
        existing.erp_funcionario_id = payload.erp_funcionario_id
    else:
        db.add(
            FingerprintTemplate(
                tenant_id=actor.tenant_id,
                erp_user_id=erp_user_id,
                erp_funcionario_id=payload.erp_funcionario_id,
                finger_type=payload.finger_type,
                template_base64=encrypted_template,
            )
        )
    db.commit()

    # Recarrega para obter o id gerado.
    template = db.scalar(
        apply_tenant(
            select(FingerprintTemplate).where(
                FingerprintTemplate.erp_user_id == erp_user_id,
                FingerprintTemplate.finger_type == payload.finger_type,
            ),
            actor,
            FingerprintTemplate,
        )
    )

    return FingerprintEnrollResponse(
        success=True,
        template_id=template.id if template else None,
        user_id=payload.user_id,
        message="Template de impressão digital registado.",
    )


@router.post("/fingerprint/identify", response_model=FingerprintResponse)
@limiter.limit("30/minute")
def identify_fingerprint(
    request: Request,
    payload: FingerprintVerifyRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("fingerprint:identify"),
) -> FingerprintResponse:
    """
    Identifica um utilizador a partir de um template de impressão digital.

    Usa matching baseado em caracteristicas locais (ORB) via OpenCV.
    E self-hosted e nao depende de SDKs de fabricantes nem servicos cloud.
    """
    from app.config import settings

    encryption = get_biometric_encryption()
    templates = db.scalars(
        apply_tenant(select(FingerprintTemplate), actor, FingerprintTemplate)
    ).all()

    references = [
        (template.erp_user_id, encryption.decrypt_text(template.template_base64))
        for template in templates
    ]

    user_id, score = best_fingerprint_match(
        payload.template_base64,
        references,
        threshold=settings.fingerprint_match_threshold,
    )

    if user_id is not None:
        return FingerprintResponse(
            success=True,
            user_id=user_id,
            message=f"Impressão digital identificada (score={score}).",
        )

    return FingerprintResponse(
        success=False,
        message="Impressão digital nao identificada.",
    )


@router.delete("/fingerprint/enroll/{user_id}")
@limiter.limit("20/hour")
def delete_fingerprint_enrollment(
    request: Request,
    user_id: str,
    finger_type: str | None = None,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("fingerprint:delete"),
) -> dict:
    """Remove o enrolamento de impressão digital de um utilizador."""
    require_self_or_manager(actor, user_id)
    stmt = apply_tenant(
        select(FingerprintTemplate).where(FingerprintTemplate.erp_user_id == user_id),
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
