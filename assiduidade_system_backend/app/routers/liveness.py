"""
Router do método "Selfie com Prova de Vida" — desafio de acção aleatório
(piscar/sorrir/virar o rosto) + verificação facial.
"""

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.biometric_metrics import biometric_metrics
from app.config import settings
from app.database import get_db
from app.deps import ActorContext, apply_tenant, get_actor
from app.limiter import limiter
from app.models import FaceTemplate
from app.schemas.common import SourceType, TemplateStatus
from app.schemas.requests import LivenessChallengeRequest, LivenessVerifyRequest
from app.services.attendance_validation import validar_metodo_assiduidade
from app.services.biometric import (
    assess_capture_quality,
    build_embedding,
    cosine_similarity,
    deserialize_embedding,
    estimate_liveness,
)
from app.services.liveness_challenge import (
    consume_challenge,
    create_challenge,
    get_challenge,
    verify_challenge_sequence,
)
from app.utils import utc_now

router = APIRouter(tags=["Liveness"])

_ACTION_PROMPT_PT = {
    "BLINK": "Pisque os olhos",
    "SMILE": "Sorria",
    "TURN_HEAD": "Vire levemente o rosto",
}


@router.post("/liveness/challenge", status_code=status.HTTP_201_CREATED)
def request_liveness_challenge(
    payload: LivenessChallengeRequest,
    actor: ActorContext = Depends(get_actor),
) -> dict:
    """Gera um desafio de prova de vida para o utilizador (válido 45s)."""
    erp_user_id = str(payload.user_id)
    challenge = create_challenge(erp_user_id)
    return {
        "challenge_id": challenge.challenge_id,
        "action": challenge.action.value,
        "prompt": _ACTION_PROMPT_PT[challenge.action.value],
        "expires_in_seconds": 45,
    }


@router.post("/liveness/verify")
@limiter.limit("20/minute")
async def verify_liveness_challenge(
    request: Request,
    payload: LivenessVerifyRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = Depends(get_actor),
) -> dict:
    """Confirma a acção do desafio e faz match facial contra o template local."""
    await validar_metodo_assiduidade(SourceType.SELFIE_GPS)

    erp_user_id = str(payload.user_id)

    challenge = get_challenge(payload.challenge_id)
    if challenge is None or challenge.user_id != erp_user_id:
        raise HTTPException(
            status_code=400,
            detail="Desafio invalido, expirado ou ja utilizado.",
        )
    consume_challenge(payload.challenge_id)

    action_passed, _action_details = verify_challenge_sequence(
        challenge.action, payload.frames_base64
    )
    if not action_passed:
        return {
            "match": False,
            "user_id": payload.user_id,
            "action": challenge.action.value,
            "action_passed": False,
            "confidence_score": 0.0,
            "liveness_score": 0.0,
            "timestamp": utc_now().isoformat(),
            "reason": "liveness_challenge_failed",
        }

    best_frame = None
    best_quality = -1.0
    for frame in payload.frames_base64:
        quality_score, quality_reason = assess_capture_quality(frame)
        if quality_reason is None and quality_score > best_quality:
            best_quality = quality_score
            best_frame = frame

    if best_frame is None:
        return {
            "match": False,
            "user_id": payload.user_id,
            "action": challenge.action.value,
            "action_passed": True,
            "confidence_score": 0.0,
            "liveness_score": 0.0,
            "timestamp": utc_now().isoformat(),
            "reason": "low_quality_capture",
        }

    try:
        probe_embedding = build_embedding(best_frame)
        liveness_score = estimate_liveness(best_frame, quality_score=best_quality)
    except ValueError:
        return {
            "match": False,
            "user_id": payload.user_id,
            "action": challenge.action.value,
            "action_passed": True,
            "confidence_score": 0.0,
            "liveness_score": 0.0,
            "timestamp": utc_now().isoformat(),
            "reason": "invalid_base64",
        }

    if liveness_score < settings.biometric_liveness_threshold:
        return {
            "match": False,
            "user_id": payload.user_id,
            "action": challenge.action.value,
            "action_passed": True,
            "confidence_score": 0.0,
            "liveness_score": liveness_score,
            "timestamp": utc_now().isoformat(),
            "reason": "liveness_failed",
        }

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
        return {
            "match": False,
            "user_id": payload.user_id,
            "action": challenge.action.value,
            "action_passed": True,
            "confidence_score": 0.0,
            "liveness_score": liveness_score,
            "timestamp": utc_now().isoformat(),
            "reason": "user_not_enrolled",
        }

    stored_embedding = deserialize_embedding(active_template.embedding)
    confidence_score = cosine_similarity(probe_embedding, stored_embedding)
    is_match = confidence_score >= settings.biometric_match_threshold

    if is_match:
        biometric_metrics.record_verify_match(confidence_score, liveness_score)
    else:
        biometric_metrics.record_verify_rejection("match_below_threshold", confidence_score, liveness_score)

    return {
        "match": is_match,
        "user_id": payload.user_id,
        "action": challenge.action.value,
        "action_passed": True,
        "confidence_score": confidence_score,
        "liveness_score": liveness_score,
        "timestamp": utc_now().isoformat(),
        "reason": None if is_match else "match_below_threshold",
    }
