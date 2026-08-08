"""
Endpoints administrativos do FaceClock (requerem credencial de servico).
"""

import base64
import json
from dataclasses import asdict
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.biometric_metrics import biometric_metrics
from app.config import settings
from app.database import get_db
from app.deps import ActorContext, apply_tenant
from app.models import BiometricAuditLog, DevicePublicKey, FaceTemplate
from app.schemas.common import TemplateStatus
from app.schemas.requests import BatchEnrollRequest
from app.security import get_biometric_encryption, require_nexora_signature
from app.security.encryption import BiometricEncryption
from app.services.biometric import cosine_similarity, deserialize_embedding, serialize_embedding
from app.services.embedding_models import get_model_version
from app.services.device_registry import (
    get_device_public_key,
    register_device_public_key,
    revoke_device_public_key,
)
from app.services.suspicious_activity import get_suspicious_activity_store
from app.utils import utc_now
from app.routers.biometric import _EnrollmentError, _perform_enrollment


router = APIRouter(tags=["Admin"])


@router.post("/admin/biometric/force-re-enroll", status_code=status.HTTP_200_OK)
def force_re_enroll(
    request: Request,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Marca todos os templates activos do tenant como PENDING_REENROLL.

    Usado quando se muda de modelo de embedding (ex.: FaceNet -> ArcFace)
    e os templates antigos precisam ser recriados. O verify rejeita
    automaticamente templates com model_version diferente do modelo activo,
    mas este endpoint permite forcar a transicao de forma controlada.
    """
    stmt = apply_tenant(
        select(FaceTemplate).where(FaceTemplate.status == TemplateStatus.ACTIVE),
        actor,
        FaceTemplate,
    )
    templates = db.scalars(stmt).all()
    updated = 0
    for template in templates:
        template.status = TemplateStatus.PENDING_REENROLL
        updated += 1
    db.commit()

    return {
        "success": True,
        "marked_for_re_enroll": updated,
        "tenant_id": actor.tenant_id,
    }


class CalibrationPair(BaseModel):
    embedding_a: list[float] = Field(..., min_length=2)
    embedding_b: list[float] = Field(..., min_length=2)
    genuine: bool  # True se os embeddings sao da mesma pessoa


class CalibrationRequest(BaseModel):
    pairs: list[CalibrationPair] = Field(..., min_length=4)
    target_far: float | None = Field(default=None, ge=0.0, le=1.0)


@router.post("/admin/biometric/calibrate-threshold", status_code=status.HTTP_200_OK)
def calibrate_threshold(
    request: Request,
    body: CalibrationRequest,
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Calcula threshold optimo a partir de pares de embeddings etiquetados.

    Devolve o threshold no ponto EER (Equal Error Rate) e, opcionalmente,
    o threshold para um FAR alvo.
    """
    genuine_scores: list[float] = []
    impostor_scores: list[float] = []

    for pair in body.pairs:
        score = cosine_similarity(pair.embedding_a, pair.embedding_b)
        if pair.genuine:
            genuine_scores.append(score)
        else:
            impostor_scores.append(score)

    if not genuine_scores or not impostor_scores:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Sao necessarios pelo menos um par genuino e um par impostor.",
        )

    all_scores = sorted(set(genuine_scores + impostor_scores))
    best_threshold = 0.0
    best_eer = 1.0
    far_at_eer = 0.0
    frr_at_eer = 0.0

    for threshold in all_scores:
        false_accepts = sum(1 for s in impostor_scores if s >= threshold)
        false_rejects = sum(1 for s in genuine_scores if s < threshold)
        far = false_accepts / len(impostor_scores)
        frr = false_rejects / len(genuine_scores)
        eer = max(far, frr)
        if eer < best_eer:
            best_eer = eer
            best_threshold = threshold
            far_at_eer = far
            frr_at_eer = frr

    result = {
        "eer_threshold": round(best_threshold, 4),
        "eer": round(best_eer, 4),
        "far_at_eer": round(far_at_eer, 4),
        "frr_at_eer": round(frr_at_eer, 4),
        "genuine_pairs": len(genuine_scores),
        "impostor_pairs": len(impostor_scores),
        "model_version": get_model_version(),
    }

    if body.target_far is not None:
        sorted_thresholds = sorted(all_scores, reverse=True)
        target_threshold = 0.0
        for threshold in sorted_thresholds:
            false_accepts = sum(1 for s in impostor_scores if s >= threshold)
            far = false_accepts / len(impostor_scores)
            if far <= body.target_far:
                target_threshold = threshold
                break
        result["target_far_threshold"] = round(target_threshold, 4)
        result["target_far"] = body.target_far

    return result


@router.post("/admin/biometric/re-encrypt", status_code=status.HTTP_200_OK)
def re_encrypt_templates(
    request: Request,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Re-encripta todos os templates do tenant com a chave activa actual.

    Usado durante rotacao de chaves: os templates sao lidos com a chave antiga
    e guardados novamente com a chave activa (`active` do keyring).
    """
    encryption = get_biometric_encryption()
    stmt = apply_tenant(
        select(FaceTemplate),
        actor,
        FaceTemplate,
    )
    templates = db.scalars(stmt).all()
    updated = 0
    failed = 0

    for template in templates:
        try:
            embedding = deserialize_embedding(template.embedding)
            plaintext = json.dumps(embedding, separators=(",", ":")).encode("utf-8")
            template.embedding = encryption.encrypt(plaintext)
            updated += 1
        except Exception:
            failed += 1

    db.commit()
    return {
        "success": True,
        "re_encrypted": updated,
        "failed": failed,
        "active_key_id": encryption.active_key_id,
        "tenant_id": actor.tenant_id,
    }


class DeviceKeyRequest(BaseModel):
    device_id: str = Field(..., min_length=1)
    public_key_b64: str = Field(..., min_length=1)


@router.post("/admin/devices/register-key", status_code=status.HTTP_201_CREATED)
def register_device_key(
    request: Request,
    body: DeviceKeyRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Regista ou actualiza a chave publica Ed25519 de um dispositivo."""
    record = register_device_public_key(
        db=db,
        actor=actor,
        device_id=body.device_id,
        public_key_b64=body.public_key_b64,
    )
    db.commit()
    return {
        "success": True,
        "device_id": record.device_id,
        "public_key_b64": record.public_key_b64,
    }


@router.get("/admin/devices/{device_id}/public-key")
def get_device_key(
    request: Request,
    device_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Devolve a chave publica activa de um dispositivo."""
    public_key = get_device_public_key(db, actor, device_id)
    if public_key is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Chave publica do dispositivo nao encontrada.",
        )
    return {"device_id": device_id, "public_key_b64": public_key}


@router.post("/admin/devices/{device_id}/revoke-key", status_code=status.HTTP_200_OK)
def revoke_device_key(
    request: Request,
    device_id: str,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Revoga a chave publica de um dispositivo."""
    revoked = revoke_device_public_key(db, actor, device_id)
    db.commit()
    if not revoked:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dispositivo nao encontrado ou ja revogado.",
        )
    return {"success": True, "device_id": device_id, "status": "revoked"}


@router.get("/admin/biometric/suspicious-activity", status_code=status.HTTP_200_OK)
def list_suspicious_activity(
    request: Request,
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Lista utilizadores/dispositivos com falhas consecutivas de verify/liveness
    acima do threshold configurado, dentro da janela deslizante.

    A store de actividade suspeita nao e uma tabela SQL (ver
    app/services/suspicious_activity.py), por isso o filtro por tenant e feito
    manualmente aqui em vez de `apply_tenant`.
    """
    store = get_suspicious_activity_store()
    tenant_filter = None if actor.role == "ADMIN_SISTEMA" else actor.tenant_id
    flagged = store.list_flagged(tenant_filter)
    return {
        "threshold": settings.suspicious_activity_threshold,
        "window_seconds": settings.suspicious_activity_window_seconds,
        "flagged": [asdict(entry) for entry in flagged],
    }


@router.get("/admin/biometric/audit-logs", status_code=status.HTTP_200_OK)
def list_audit_logs_local(
    request: Request,
    event_type: str | None = Query(default=None),
    erp_user_id: str | None = Query(default=None),
    device_id: str | None = Query(default=None),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("audit:read"),
) -> dict:
    """Consulta o audit log local de eventos biometricos (enroll/verify/
    identify/liveness). Complementa GET /audit/logs, que delega ao ERP."""
    stmt = apply_tenant(select(BiometricAuditLog), actor, BiometricAuditLog)
    if event_type:
        stmt = stmt.where(BiometricAuditLog.event_type == event_type)
    if erp_user_id:
        stmt = stmt.where(BiometricAuditLog.erp_user_id == erp_user_id)
    if device_id:
        stmt = stmt.where(BiometricAuditLog.device_id == device_id)
    if date_from:
        stmt = stmt.where(BiometricAuditLog.created_at >= date_from)
    if date_to:
        stmt = stmt.where(BiometricAuditLog.created_at <= date_to)

    stmt = stmt.order_by(BiometricAuditLog.created_at.desc())
    rows = db.scalars(stmt.offset((page - 1) * limit).limit(limit)).all()

    return {
        "page": page,
        "limit": limit,
        "data": [
            {
                "id": row.id,
                "tenant_id": row.tenant_id,
                "event_type": row.event_type,
                "erp_user_id": row.erp_user_id,
                "device_id": row.device_id,
                "reason": row.reason,
                "confidence_score": float(row.confidence_score) if row.confidence_score is not None else None,
                "liveness_score": float(row.liveness_score) if row.liveness_score is not None else None,
                "created_at": row.created_at.isoformat(),
            }
            for row in rows
        ],
    }


@router.get("/admin/biometric/metrics-dashboard", status_code=status.HTTP_200_OK)
def metrics_dashboard(
    request: Request,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Vista agregada de operacao biometrica: metricas de processo, actividade
    suspeita e resumo do audit log das ultimas 24h.

    Nota de design: `biometric_metrics` e um singleton global do processo
    (sem tenant_id) — nao e filtravel por tenant, tal como o `/metrics`
    Prometheus existente. As seccoes `suspicious_activity` e
    `audit_summary_24h`, essas sim, sao filtradas por tenant. Esta assimetria
    dentro do mesmo payload e intencional.
    """
    biometric = {
        "far_rate": biometric_metrics.far_rate,
        "frr_rate": biometric_metrics.frr_rate,
        "match_rate": biometric_metrics.match_rate,
        "avg_confidence": biometric_metrics.avg_confidence,
        "avg_liveness": biometric_metrics.avg_liveness,
        "apcer": biometric_metrics.apcer,
        "bpcer": biometric_metrics.bpcer,
        "eer_estimate": biometric_metrics.eer_estimate,
        "total_enroll_attempts": biometric_metrics.total_enroll_attempts,
        "total_enroll_success": biometric_metrics.total_enroll_success,
        "total_verify_attempts": biometric_metrics.total_verify_attempts,
        "total_verify_matches": biometric_metrics.total_verify_matches,
        "total_verify_rejections": biometric_metrics.total_verify_rejections,
        "scope": "process-wide",
    }

    tenant_filter = None if actor.role == "ADMIN_SISTEMA" else actor.tenant_id
    flagged = get_suspicious_activity_store().list_flagged(tenant_filter)

    audit_stmt = apply_tenant(
        select(BiometricAuditLog.event_type, func.count())
        .where(BiometricAuditLog.created_at >= utc_now() - timedelta(hours=24))
        .group_by(BiometricAuditLog.event_type),
        actor,
        BiometricAuditLog,
    )
    audit_summary_24h = dict(db.execute(audit_stmt).all())

    return {
        "biometric_metrics": biometric,
        "suspicious_activity": {
            "threshold": settings.suspicious_activity_threshold,
            "window_seconds": settings.suspicious_activity_window_seconds,
            "flagged_count": len(flagged),
            "flagged": [asdict(entry) for entry in flagged],
        },
        "audit_summary_24h": audit_summary_24h,
    }


@router.get("/admin/biometric/export-templates", status_code=status.HTTP_200_OK)
def export_templates(
    request: Request,
    erp_user_id: str | None = Query(default=None),
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Exporta os templates faciais do tenant para backup/migracao.

    O campo `embedding_b64` e o ciphertext tal como esta guardado (AES-GCM,
    `enc:v2:...`) — so e decifravel num ambiente com a mesma
    BIOMETRIC_ENCRYPTION_KEY/keyring. Nao inclui `embedding_vector` (dados
    derivados, reconstruiveis a partir do embedding decifrado).
    """
    stmt = apply_tenant(select(FaceTemplate), actor, FaceTemplate)
    if erp_user_id:
        stmt = stmt.where(FaceTemplate.erp_user_id == erp_user_id)

    templates = db.scalars(stmt).all()

    return {
        "exported_at": utc_now().isoformat(),
        "count": len(templates),
        "templates": [
            {
                "id": template.id,
                "tenant_id": template.tenant_id,
                "erp_user_id": template.erp_user_id,
                "erp_funcionario_id": template.erp_funcionario_id,
                "consent_version": template.consent_version,
                "model_version": template.model_version,
                "embedding_b64": base64.b64encode(template.embedding).decode("ascii"),
                "transform_version": template.transform_version,
                "quality_score": float(template.quality_score) if template.quality_score is not None else None,
                "status": template.status.value,
                "created_at": template.created_at.isoformat(),
                "revoked_at": template.revoked_at.isoformat() if template.revoked_at else None,
            }
            for template in templates
        ],
    }


@router.post("/admin/biometric/batch-enroll", status_code=status.HTTP_200_OK)
async def batch_enroll_biometric(
    request: Request,
    body: BatchEnrollRequest,
    db: Session = Depends(get_db),
    actor: ActorContext = require_nexora_signature("biometric:admin"),
) -> dict:
    """Enrolamento em massa (migracoes/onboarding em lote).

    Cada item e processado e comitado de forma independente (via o mesmo
    helper _perform_enrollment usado por /biometric/enroll) — um item falhar
    nao desfaz nem bloqueia os restantes.
    """
    results = []
    success_count = 0
    for item in body.enrollments:
        erp_user_id = str(item.user_id)
        try:
            template = await _perform_enrollment(db, actor, erp_user_id, item.captures)
        except _EnrollmentError as exc:
            results.append({
                "user_id": erp_user_id,
                "success": False,
                "error": exc.detail,
            })
            continue
        success_count += 1
        results.append({
            "user_id": erp_user_id,
            "success": True,
            "template_id": template.id,
        })

    return {
        "total": len(body.enrollments),
        "success_count": success_count,
        "failure_count": len(body.enrollments) - success_count,
        "results": results,
    }
