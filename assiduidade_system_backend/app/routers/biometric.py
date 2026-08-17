import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.biometric_metrics import biometric_metrics
from app.config import settings
from app.database import get_db
from app.deps import ActorContext, apply_tenant, require_self_or_manager
from app.security import require_nexora_signature
from app.security.image_signature import verify_image_signature
from app.limiter import limiter
from app.models import FaceTemplate
from app.schemas.common import SourceType, TemplateStatus
from app.schemas.requests import EnrollRequest, IdentifyRequest, VerifyRequest
from app.schemas.responses import EnrollResponse, VerifyResponse
from app.services.attendance_validation import validar_metodo_assiduidade
from app.services.biometric import (
    _get_cancelable_transform,
    apply_cancelable_transform,
    assess_capture_quality,
    average_embeddings,
    build_embedding,
    cosine_similarity,
    deserialize_embedding,
    estimate_liveness,
    serialize_embedding,
)
from app.services.audit_log import record_audit_event
from app.services.device_registry import get_device_public_key
from app.services.embedding_models import get_model_version
from app.services.suspicious_activity import record_verify_failure, record_verify_success
from app.security.facial_verification import issue_facial_verification_token
from app.erp_client import erp_client
from app.utils import utc_now

log = logging.getLogger(__name__)


def _validate_image_signature(
    db: Session,
    actor: ActorContext,
    device_id: str,
    image_base64: str | None,
    image_url: str | None,
    image_signature: str | None,
) -> None:
    """Valida a assinatura da imagem contra a chave publica registada do
    dispositivo (device_registry). A chave nunca e aceite a partir do
    pedido do cliente — so uma chave registada previamente por um admin
    via /admin/devices/register-key e considerada de confianca.
    """
    if settings.require_image_signature and not image_signature:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Assinatura da imagem obrigatoria (REQUIRE_IMAGE_SIGNATURE=true).",
        )
    if image_signature:
        public_key = get_device_public_key(db, actor, device_id)
        if public_key is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Chave publica do dispositivo nao encontrada.",
            )
        message = image_base64 or image_url or ""
        if not verify_image_signature(public_key, message, image_signature):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Assinatura da imagem invalida.",
            )


router = APIRouter(tags=["Biometric"])


class _EnrollmentError(Exception):
    """Erro de enrolamento com status/detail HTTP ja resolvidos.

    Usado pelo helper partilhado _perform_enrollment para que tanto o
    endpoint single-user como o batch consigam decidir o que fazer com a
    falha (raise directo vs. registar como item falhado do lote).
    """

    def __init__(self, status_code: int, detail: str) -> None:
        self.status_code = status_code
        self.detail = detail
        super().__init__(detail)


async def _perform_enrollment(
    db: Session,
    actor: ActorContext,
    erp_user_id: str,
    captures: list,
) -> FaceTemplate:
    """Logica partilhada de enrolamento (consentimento LGPD + qualidade +
    liveness + embedding por captura + template final). Comita a cada ponto
    de falha/sucesso, para que o batch-enroll consiga isolar cada item numa
    transaccao propria sem perder o trabalho de itens ja bem sucedidos.

    Levanta _EnrollmentError em vez de HTTPException para que o chamador
    decida a forma da resposta (single-user aborta o pedido; batch continua
    para o proximo item).
    """
    require_self_or_manager(actor, erp_user_id)

    approved_embeddings: list[list[float]] = []
    approved_quality_scores: list[float] = []
    for idx, capture in enumerate(captures):
        try:
            quality_score, quality_reason = assess_capture_quality(
                image_base64=capture.image_base64,
                image_url=capture.image_url,
            )
            embedding = build_embedding(
                image_base64=capture.image_base64,
                image_url=capture.image_url,
            )
            liveness_score = estimate_liveness(
                image_base64=capture.image_base64,
                image_url=capture.image_url,
                quality_score=quality_score,
            )
        except ValueError as exc:
            biometric_metrics.record_enroll_failure()
            record_audit_event(db, actor.tenant_id, "enroll_failure", erp_user_id=erp_user_id, reason="invalid_image")
            db.commit()
            raise _EnrollmentError(400, f"Captura {idx + 1} invalida: {exc}.") from None
        except RuntimeError as exc:
            biometric_metrics.record_enroll_failure()
            record_audit_event(db, actor.tenant_id, "enroll_failure", erp_user_id=erp_user_id, reason="model_unavailable")
            db.commit()
            raise _EnrollmentError(
                status.HTTP_503_SERVICE_UNAVAILABLE, "Modelo biometrico indisponivel no servidor."
            ) from exc
        except Exception as exc:
            biometric_metrics.record_enroll_failure()
            record_audit_event(db, actor.tenant_id, "enroll_failure", erp_user_id=erp_user_id, reason=type(exc).__name__)
            db.commit()
            raise _EnrollmentError(
                422, f"Erro ao processar captura {idx + 1}: {type(exc).__name__}."
            ) from exc
        if quality_reason or quality_score < settings.biometric_quality_threshold:
            biometric_metrics.record_enroll_failure()
            record_audit_event(
                db, actor.tenant_id, "enroll_failure", erp_user_id=erp_user_id,
                reason=quality_reason or "low_quality_capture",
            )
            db.commit()
            raise _EnrollmentError(
                400,
                f"Captura {idx + 1} invalida: {quality_reason or 'low_quality_capture'} (score={quality_score:.2f}).",
            )
        if liveness_score < settings.biometric_liveness_threshold:
            biometric_metrics.record_enroll_failure()
            record_audit_event(
                db, actor.tenant_id, "enroll_failure", erp_user_id=erp_user_id,
                reason="liveness_failed", liveness_score=liveness_score,
            )
            db.commit()
            raise _EnrollmentError(
                400, f"Captura {idx + 1} invalida: liveness_failed (score={liveness_score:.2f})."
            )
        approved_quality_scores.append(quality_score)
        approved_embeddings.append(embedding)

    if len(approved_embeddings) < 3:
        raise _EnrollmentError(400, "Enrollment exige ao menos 3 capturas validas.")

    template_embedding = average_embeddings(approved_embeddings)
    template_embedding, transform_version = apply_cancelable_transform(template_embedding)
    average_quality = round(sum(approved_quality_scores) / len(approved_quality_scores), 4)

    template = FaceTemplate(
        tenant_id=actor.tenant_id,
        erp_user_id=erp_user_id,
        model_version=get_model_version(),
        embedding=serialize_embedding(template_embedding),
        # embedding_vector so e populado quando a transformacao cancelavel esta
        # activa: sem ela, o vector ficaria legivel em claro por qualquer leitor
        # da BD (a coluna existe para pesquisa pgvector 1:N, nao pode ser
        # cifrada com AES-GCM como a coluna `embedding`).
        embedding_vector=template_embedding if transform_version else None,
        transform_version=transform_version,
        quality_score=average_quality,
        status=TemplateStatus.ACTIVE,
    )
    db.add(template)
    record_audit_event(db, actor.tenant_id, "enroll_success", erp_user_id=erp_user_id)
    db.commit()
    biometric_metrics.record_enroll_success()
    return template


@router.post(
    "/biometric/enroll",
    response_model=EnrollResponse,
    status_code=status.HTTP_201_CREATED,
)
@limiter.limit("20/hour")
async def enroll_biometric(
    request: Request,
    payload: EnrollRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:enroll"),
) -> EnrollResponse:
    erp_user_id = str(payload.user_id)
    try:
        template = await _perform_enrollment(db, actor, erp_user_id, payload.captures)
    except _EnrollmentError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.detail) from None

    return EnrollResponse(
        template_id=template.id,
        user_id=payload.user_id,
        model_version=template.model_version,
        status=template.status,
    )


@router.post("/biometric/verify", response_model=VerifyResponse)
# 30/minute fazia sentido quando cada telemóvel chamava o FaceClock
# directamente (limite por dispositivo, via get_remote_address). Agora que o
# ERP faz proxy deste endpoint, todos os tenants/funcionários partilham o
# mesmo IP de origem — 30/min para a plataforma inteira rejeitava verificações
# legítimas em hora de ponta. Subido para um valor que serve de protecção
# contra abuso grosseiro sem colidir com uso normal multi-tenant.
@limiter.limit("1000/minute")
async def verify_biometric(
    request: Request,
    payload: VerifyRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:verify"),
) -> VerifyResponse:
    await validar_metodo_assiduidade(SourceType.FACIAL)

    _validate_image_signature(
        db,
        actor,
        str(payload.device_id),
        payload.image_base64,
        payload.image_url,
        payload.image_signature,
    )

    erp_user_id = str(payload.user_id)
    require_self_or_manager(actor, erp_user_id)

    try:
        quality_score, quality_reason = assess_capture_quality(
            image_base64=payload.image_base64,
            image_url=payload.image_url,
        )
        probe_embedding = build_embedding(
            image_base64=payload.image_base64,
            image_url=payload.image_url,
        )
        liveness_score = estimate_liveness(
            image_base64=payload.image_base64,
            image_url=payload.image_url,
            quality_score=quality_score,
        )
    except ValueError:
        record_verify_failure(actor.tenant_id, erp_user_id, str(payload.device_id), "invalid_image")
        record_audit_event(
            db, actor.tenant_id, "verify_rejection", erp_user_id=erp_user_id,
            device_id=str(payload.device_id), reason="invalid_image",
        )
        db.commit()
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=0.0,
            timestamp=utc_now(),
            reason="invalid_image",
        )
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Modelo biometrico indisponivel no servidor.",
        ) from exc

    if quality_reason or quality_score < settings.biometric_quality_threshold:
        reason = quality_reason or "low_quality_capture"
        biometric_metrics.record_verify_rejection(reason, 0.0, 0.0, liveness_passed=True)
        record_verify_failure(actor.tenant_id, erp_user_id, str(payload.device_id), reason)
        record_audit_event(
            db, actor.tenant_id, "verify_rejection", erp_user_id=erp_user_id,
            device_id=str(payload.device_id), reason=reason,
        )
        db.commit()
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=0.0,
            timestamp=utc_now(),
            reason=reason,
        )

    if liveness_score < settings.biometric_liveness_threshold:
        biometric_metrics.record_verify_rejection("liveness_failed", 0.0, liveness_score, liveness_passed=False)
        record_verify_failure(actor.tenant_id, erp_user_id, str(payload.device_id), "liveness_failed")
        record_audit_event(
            db, actor.tenant_id, "verify_rejection", erp_user_id=erp_user_id,
            device_id=str(payload.device_id), reason="liveness_failed", liveness_score=liveness_score,
        )
        db.commit()
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
                FaceTemplate.erp_user_id == erp_user_id,
                FaceTemplate.status == TemplateStatus.ACTIVE,
            ),
            actor,
            FaceTemplate,
        )
    )
    if not active_template:
        record_verify_failure(actor.tenant_id, erp_user_id, str(payload.device_id), "user_not_enrolled")
        record_audit_event(
            db, actor.tenant_id, "verify_rejection", erp_user_id=erp_user_id,
            device_id=str(payload.device_id), reason="user_not_enrolled", liveness_score=liveness_score,
        )
        db.commit()
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=liveness_score,
            timestamp=utc_now(),
            reason="user_not_enrolled",
        )

    current_model_version = get_model_version()
    if active_template.model_version != current_model_version:
        # Marca o template como pendente de re-enrolamento automaticamente.
        if active_template.status != TemplateStatus.PENDING_REENROLL:
            old_model_version = active_template.model_version
            active_template.status = TemplateStatus.PENDING_REENROLL
            db.commit()
            # So notifica na 1a transicao, para nao espalhar o webhook a cada
            # tentativa de verify enquanto o template estiver pendente.
            await erp_client.notify_reenroll_required(
                erp_user_id=erp_user_id,
                tenant_id=actor.tenant_id,
                old_model_version=old_model_version,
                new_model_version=current_model_version,
            )
        biometric_metrics.record_verify_rejection(
            "model_version_mismatch", 0.0, liveness_score, liveness_passed=True
        )
        record_verify_failure(actor.tenant_id, erp_user_id, str(payload.device_id), "model_version_mismatch")
        record_audit_event(
            db, actor.tenant_id, "verify_rejection", erp_user_id=erp_user_id,
            device_id=str(payload.device_id), reason="model_version_mismatch", liveness_score=liveness_score,
        )
        db.commit()
        return VerifyResponse(
            match=False,
            user_id=payload.user_id,
            confidence_score=0.0,
            liveness_score=liveness_score,
            timestamp=utc_now(),
            reason="model_version_mismatch",
        )

    stored_embedding = deserialize_embedding(active_template.embedding)

    # Se o template foi guardado com transformacao cancelavel, aplicar a mesma
    # transformacao ao probe antes de comparar.
    if active_template.transform_version:
        transform = _get_cancelable_transform()
        if transform is None or transform.version != active_template.transform_version:
            biometric_metrics.record_verify_rejection(
                "transform_version_mismatch", 0.0, liveness_score, liveness_passed=True
            )
            record_verify_failure(actor.tenant_id, erp_user_id, str(payload.device_id), "transform_version_mismatch")
            record_audit_event(
                db, actor.tenant_id, "verify_rejection", erp_user_id=erp_user_id,
                device_id=str(payload.device_id), reason="transform_version_mismatch", liveness_score=liveness_score,
            )
            db.commit()
            return VerifyResponse(
                match=False,
                user_id=payload.user_id,
                confidence_score=0.0,
                liveness_score=liveness_score,
                timestamp=utc_now(),
                reason="transform_version_mismatch",
            )
        probe_embedding, _ = apply_cancelable_transform(probe_embedding)

    confidence_score = cosine_similarity(probe_embedding, stored_embedding)
    is_match = confidence_score >= settings.biometric_match_threshold

    liveness_passed = liveness_score >= settings.biometric_liveness_threshold
    if is_match:
        biometric_metrics.record_verify_match(confidence_score, liveness_score, liveness_passed)
        record_verify_success(actor.tenant_id, erp_user_id, str(payload.device_id))
        record_audit_event(
            db, actor.tenant_id, "verify_match", erp_user_id=erp_user_id,
            device_id=str(payload.device_id), confidence_score=confidence_score, liveness_score=liveness_score,
        )
    else:
        reason = "match_below_threshold"
        biometric_metrics.record_verify_rejection(reason, confidence_score, liveness_score, liveness_passed)
        record_verify_failure(actor.tenant_id, erp_user_id, str(payload.device_id), reason)
        record_audit_event(
            db, actor.tenant_id, "verify_rejection", erp_user_id=erp_user_id, device_id=str(payload.device_id),
            reason=reason, confidence_score=confidence_score, liveness_score=liveness_score,
        )
    db.commit()

    verification_token = None
    verification_tenant_id = active_template.tenant_id or actor.tenant_id
    if is_match and verification_tenant_id:
        verification_token = issue_facial_verification_token(
            tenant_id=str(verification_tenant_id),
            user_id=erp_user_id,
            device_id=str(payload.device_id),
            confidence_score=confidence_score,
            liveness_score=liveness_score,
        )

    return VerifyResponse(
        match=is_match,
        user_id=payload.user_id,
        confidence_score=confidence_score,
        liveness_score=liveness_score,
        timestamp=utc_now(),
        reason=None if is_match else "match_below_threshold",
        verification_token=verification_token,
    )


@router.post("/biometric/identify")
@limiter.limit("100/minute")
def identify_biometric(
    request: Request,
    payload: IdentifyRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:identify"),
) -> dict:
    """Identificacao 1:N: procura o utilizador mais provavel entre todos os
    templates activos do tenant usando pgvector (cosine similarity).

    Requer que a extensao pgvector esteja activa e a coluna embedding_vector
    populada. Caso contrario, retorna 503.
    """
    _validate_image_signature(
        db,
        actor,
        str(payload.device_id),
        payload.image_base64,
        payload.image_url,
        payload.image_signature,
    )

    try:
        quality_score, quality_reason = assess_capture_quality(
            image_base64=payload.image_base64,
            image_url=payload.image_url,
        )
        probe_embedding = build_embedding(
            image_base64=payload.image_base64,
            image_url=payload.image_url,
        )
        probe_embedding, probe_transform_version = apply_cancelable_transform(probe_embedding)
        liveness_score = estimate_liveness(
            image_base64=payload.image_base64,
            image_url=payload.image_url,
            quality_score=quality_score,
        )
    except ValueError as exc:
        record_audit_event(
            db, actor.tenant_id, "identify_no_match", device_id=str(payload.device_id), reason="invalid_image",
        )
        db.commit()
        raise HTTPException(
            status_code=400,
            detail=f"Captura invalida: {exc}.",
        ) from None
    except RuntimeError as exc:
        record_audit_event(
            db, actor.tenant_id, "identify_no_match", device_id=str(payload.device_id), reason="model_unavailable",
        )
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Modelo biometrico indisponivel no servidor.",
        ) from exc

    if quality_reason or quality_score < settings.biometric_quality_threshold:
        record_audit_event(
            db, actor.tenant_id, "identify_no_match", device_id=str(payload.device_id),
            reason=quality_reason or "low_quality_capture",
        )
        db.commit()
        raise HTTPException(
            status_code=400,
            detail=f"Captura invalida: {quality_reason or 'low_quality_capture'} (score={quality_score:.2f}).",
        )

    if liveness_score < settings.biometric_liveness_threshold:
        record_audit_event(
            db, actor.tenant_id, "identify_no_match", device_id=str(payload.device_id),
            reason="liveness_failed", liveness_score=liveness_score,
        )
        db.commit()
        raise HTTPException(
            status_code=400,
            detail=f"Captura invalida: liveness_failed (score={liveness_score:.2f}).",
        )

    try:
        from pgvector.sqlalchemy import Vector  # type: ignore[import-untyped]
    except ImportError as exc:
        record_audit_event(
            db, actor.tenant_id, "identify_no_match", device_id=str(payload.device_id), reason="pgvector_unavailable",
        )
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="pgvector nao esta instalado.",
        ) from exc

    current_version = get_model_version()
    try:
        stmt = (
            select(
                FaceTemplate.erp_user_id,
                FaceTemplate.embedding_vector.cosine_distance(probe_embedding).label("distance"),
            )
            .where(
                FaceTemplate.tenant_id == actor.tenant_id,
                FaceTemplate.status == TemplateStatus.ACTIVE,
                FaceTemplate.model_version == current_version,
                FaceTemplate.embedding_vector.isnot(None),
                FaceTemplate.transform_version == probe_transform_version,
            )
            .order_by(FaceTemplate.embedding_vector.cosine_distance(probe_embedding))
            .limit(payload.top_k)
        )
        rows = db.execute(stmt).all()
    except Exception as exc:
        log.exception("Erro na busca pgvector 1:N")
        record_audit_event(
            db, actor.tenant_id, "identify_no_match", device_id=str(payload.device_id), reason="search_error",
        )
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Erro na busca por similaridade: {exc}",
        ) from exc

    results = []
    for candidate_user_id, distance in rows:
        if distance is None:
            continue
        similarity = 1.0 - float(distance)
        if similarity >= settings.biometric_match_threshold:
            results.append({
                "user_id": candidate_user_id,
                "confidence_score": round(similarity, 4),
            })

    if results:
        record_audit_event(
            db, actor.tenant_id, "identify_match", erp_user_id=results[0]["user_id"],
            device_id=str(payload.device_id), confidence_score=results[0]["confidence_score"],
            liveness_score=liveness_score,
        )
    else:
        record_audit_event(
            db, actor.tenant_id, "identify_no_match", device_id=str(payload.device_id),
            reason="no_candidate_above_threshold", liveness_score=liveness_score,
        )
    db.commit()

    return {
        "match": len(results) > 0,
        "candidates": results,
        "liveness_score": liveness_score,
        "timestamp": utc_now(),
    }
