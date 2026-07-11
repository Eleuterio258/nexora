from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.audit_chain import chain_audit_hash
from app.biometric_metrics import biometric_metrics
from app.config import settings
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.limiter import limiter
from app.models import AuditLogModel, Consent, FaceTemplate, User
from app.schemas.common import TemplateStatus
from app.schemas.requests import EnrollRequest, VerifyRequest
from app.schemas.responses import EnrollResponse, VerifyResponse
from app.services.biometric import (
    MODEL_VERSION,
    assess_capture_quality,
    average_embeddings,
    build_embedding,
    cosine_similarity,
    deserialize_embedding,
    estimate_liveness,
    serialize_embedding,
)
from app.utils import utc_now


router = APIRouter(tags=["Biometric"])


@router.post(
    "/biometric/enroll",
    response_model=EnrollResponse,
    status_code=status.HTTP_201_CREATED,
)
@limiter.limit("20/hour")
def enroll_biometric(
    request: Request,
    payload: EnrollRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> EnrollResponse:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == str(payload.user_id)), actor, User)
    )
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

    consent = db.scalar(
        apply_tenant(
            select(Consent)
            .where(Consent.user_id == user.id, Consent.revoked_at.is_(None))
            .order_by(Consent.accepted_at.desc()),
            actor,
            Consent,
        )
    )
    if not consent:
        raise HTTPException(
            status_code=403,
            detail="Consentimento ativo obrigatorio para cadastro biometrico.",
        )

    approved_embeddings: list[list[float]] = []
    approved_quality_scores: list[float] = []
    for idx, capture in enumerate(payload.captures):
        try:
            quality_score, quality_reason = assess_capture_quality(capture.image_base64)
            embedding = build_embedding(capture.image_base64)
            liveness_score = estimate_liveness(
                capture.image_base64,
                quality_score=quality_score,
            )
        except ValueError as exc:
            biometric_metrics.record_enroll_failure()
            raise HTTPException(
                status_code=400,
                detail=f"Captura {idx + 1} invalida: {exc}.",
            ) from None
        except Exception as exc:
            biometric_metrics.record_enroll_failure()
            raise HTTPException(
                status_code=422,
                detail=f"Erro ao processar captura {idx + 1}: {type(exc).__name__}.",
            ) from exc
        if quality_reason or quality_score < settings.biometric_quality_threshold:
            biometric_metrics.record_enroll_failure()
            raise HTTPException(
                status_code=400,
                detail=f"Captura {idx + 1} invalida: {quality_reason or 'low_quality_capture'} (score={quality_score:.2f}).",
            )
        if liveness_score < settings.biometric_liveness_threshold:
            biometric_metrics.record_enroll_failure()
            raise HTTPException(
                status_code=400,
                detail=f"Captura {idx + 1} invalida: liveness_failed (score={liveness_score:.2f}).",
            )
        approved_quality_scores.append(quality_score)
        approved_embeddings.append(embedding)

    if len(approved_embeddings) < 3:
        raise HTTPException(
            status_code=400,
            detail="Enrollment exige ao menos 3 capturas validas.",
        )

    template_embedding = average_embeddings(approved_embeddings)
    average_quality = round(sum(approved_quality_scores) / len(approved_quality_scores), 4)

    template = FaceTemplate(
        tenant_id=actor.tenant_id,
        user_id=user.id,
        consent_id=consent.id,
        model_version=MODEL_VERSION,
        embedding=serialize_embedding(template_embedding),
        quality_score=average_quality,
        status=TemplateStatus.ACTIVE,
    )
    db.add(template)
    db.flush()
    biometric_metrics.record_enroll_success()

    chained_hash = chain_audit_hash(db, consent.consent_hash)
    db.add(
        AuditLogModel(
            tenant_id=actor.tenant_id,
            actor_type=actor.role,
            actor_id=actor.id or str(payload.user_id),
            action="BIOMETRIC_ENROLL",
            entity_type="face_template",
            entity_id=template.id,
            payload_hash=consent.consent_hash,
            previous_hash=chained_hash,
        )
    )
    db.commit()
    return EnrollResponse(
        template_id=template.id,
        user_id=payload.user_id,
        model_version=template.model_version,
        status=template.status,
    )


@router.post("/biometric/verify", response_model=VerifyResponse)
@limiter.limit("30/minute")
def verify_biometric(
    request: Request,
    payload: VerifyRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> VerifyResponse:
    user = db.scalar(
        apply_tenant(select(User).where(User.id == str(payload.user_id)), actor, User)
    )
    if not user:
        raise HTTPException(status_code=422, detail="Usuario invalido.")

    try:
        quality_score, quality_reason = assess_capture_quality(payload.image_base64)
        probe_embedding = build_embedding(payload.image_base64)
        liveness_score = estimate_liveness(payload.image_base64, quality_score=quality_score)
    except ValueError:
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=0.0,
            timestamp=utc_now(),
            reason="invalid_base64",
        )

    if quality_reason or quality_score < settings.biometric_quality_threshold:
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=0.0,
            timestamp=utc_now(),
            reason=quality_reason or "low_quality_capture",
        )

    if liveness_score < settings.biometric_liveness_threshold:
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=liveness_score,
            timestamp=utc_now(),
            reason="liveness_failed",
        )

    active_template = db.scalar(
        apply_tenant(
            select(FaceTemplate).where(
                FaceTemplate.user_id == str(payload.user_id),
                FaceTemplate.status == TemplateStatus.ACTIVE,
            ),
            actor,
            FaceTemplate,
        )
    )
    if not active_template:
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=liveness_score,
            timestamp=utc_now(),
            reason="user_not_enrolled",
        )

    stored_embedding = deserialize_embedding(active_template.embedding)
    confidence_score = cosine_similarity(probe_embedding, stored_embedding)
    is_match = confidence_score >= settings.biometric_match_threshold

    if is_match:
        biometric_metrics.record_verify_match(confidence_score, liveness_score)
    else:
        reason = "match_below_threshold"
        biometric_metrics.record_verify_rejection(reason, confidence_score, liveness_score)

    return VerifyResponse(
        match=is_match,
        user_id=payload.user_id,
        confidence_score=confidence_score,
        liveness_score=liveness_score,
        timestamp=utc_now(),
        reason=None if is_match else "match_below_threshold",
    )
