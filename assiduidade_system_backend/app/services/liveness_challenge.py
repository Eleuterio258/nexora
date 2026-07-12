"""
Prova de Vida com desafio de acção aleatório (piscar / sorrir / virar o rosto) —
método "Selfie com Prova de Vida" da especificação (docs/readme.md, RF/método 6),
até agora não implementado (só existia a heurística estática de imagem única em
`estimate_liveness`, que continua a ser usada como camada adicional aqui, não
substituída).

Diferença face a `estimate_liveness()`: aquela função avalia UMA imagem (textura,
frequência, variância de cor) — não prova vivacidade real, só reduz a
probabilidade de ser uma foto/ecrã de má qualidade. Este módulo analisa uma
SEQUÊNCIA de frames e verifica se a acção pedida (ex.: piscar) aconteceu de
facto ao longo do tempo — isso é o que distingue uma pessoa real de uma foto
estática ou de um vídeo em loop que não reage ao desafio pedido.

Não usa nenhum SDK de liveness comercial (nenhum está instalado — ver
stakeholders-and-constraints.md); a detecção da acção é feita com os mesmos
68 landmarks dlib já usados em `services/biometric.py`, sem dependências novas.
"""

import logging
import math
import time
import uuid
from dataclasses import dataclass, field
from enum import Enum

import numpy as np

from app.services.biometric import FACE_RECOGNITION_AVAILABLE, _base64_to_numpy

log = logging.getLogger("faceclock.liveness_challenge")


class ChallengeAction(str, Enum):
    BLINK = "BLINK"
    SMILE = "SMILE"
    TURN_HEAD = "TURN_HEAD"


# ─── Limiares de detecção (calibrados por inspecção visual, não por dataset —
# documentado assim de propósito: ajustar se houver falsos positivos/negativos
# em uso real) ──────────────────────────────────────────────────────────────
_EAR_BLINK_DROP = 0.22          # EAR abaixo disto = olho considerado fechado
_EAR_OPEN_MIN = 0.28            # EAR precisa voltar a isto para contar como "reabriu"
_SMILE_RATIO_INCREASE = 0.18    # aumento relativo mínimo na largura da boca
_TURN_DEVIATION_MIN = 0.12      # desvio mínimo da posição do nariz (proporção 0-1)

_CHALLENGE_TTL_SECONDS = 45
_MIN_FRAMES = 4
_MAX_FRAMES = 20


@dataclass
class LivenessChallenge:
    challenge_id: str
    action: ChallengeAction
    user_id: str
    created_at: float
    used: bool = False


# Store em memória — mesma limitação já documentada em app/routers/methods.py
# (`_qr_store`): em produção com múltiplas réplicas, isto precisa de um cache
# partilhado (Redis). Aceitável para o estado actual (single-instance).
_challenges: dict[str, LivenessChallenge] = {}


def create_challenge(user_id: str) -> LivenessChallenge:
    """Gera um desafio aleatório para o utilizador, válido por um curto período."""
    import random

    action = random.choice(list(ChallengeAction))
    challenge = LivenessChallenge(
        challenge_id=str(uuid.uuid4()),
        action=action,
        user_id=user_id,
        created_at=time.monotonic(),
    )
    _challenges[challenge.challenge_id] = challenge
    return challenge


def get_challenge(challenge_id: str) -> LivenessChallenge | None:
    challenge = _challenges.get(challenge_id)
    if challenge is None:
        return None
    if challenge.used or (time.monotonic() - challenge.created_at) > _CHALLENGE_TTL_SECONDS:
        return None
    return challenge


def consume_challenge(challenge_id: str) -> None:
    """Marca o desafio como usado, impedindo replay do mesmo challenge_id."""
    challenge = _challenges.get(challenge_id)
    if challenge:
        challenge.used = True


def _dist(p1: tuple[float, float], p2: tuple[float, float]) -> float:
    return math.hypot(p1[0] - p2[0], p1[1] - p2[1])


def _extract_landmarks(image_base64: str) -> dict | None:
    """Devolve o dict de landmarks (face_recognition) do primeiro rosto detectado,
    ou None se não houver rosto ou a lib não estiver disponível."""
    if not FACE_RECOGNITION_AVAILABLE:
        return None
    img = _base64_to_numpy(image_base64)
    if img is None:
        return None

    import cv2
    import face_recognition

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    face_locations = face_recognition.face_locations(img_rgb, model="hog")
    if not face_locations:
        return None
    landmarks_list = face_recognition.face_landmarks(img_rgb, face_locations)
    if not landmarks_list:
        return None
    return landmarks_list[0]


def _eye_aspect_ratio(eye_points: list[tuple[float, float]]) -> float | None:
    """EAR clássico (Soukupová & Čech): (|p2-p6| + |p3-p5|) / (2 * |p1-p4|)."""
    if len(eye_points) != 6:
        return None
    p1, p2, p3, p4, p5, p6 = eye_points
    horizontal = _dist(p1, p4)
    if horizontal == 0:
        return None
    return (_dist(p2, p6) + _dist(p3, p5)) / (2.0 * horizontal)


def _frame_metrics(landmarks: dict) -> dict[str, float] | None:
    """Extrai as métricas usadas pelos 3 desafios a partir dos landmarks de um frame."""
    left_eye = landmarks.get("left_eye", [])
    right_eye = landmarks.get("right_eye", [])
    top_lip = landmarks.get("top_lip", [])
    if not left_eye or not right_eye or not top_lip:
        return None

    ear_left = _eye_aspect_ratio(left_eye)
    ear_right = _eye_aspect_ratio(right_eye)
    if ear_left is None or ear_right is None:
        return None
    ear = (ear_left + ear_right) / 2.0

    left_eye_center = (
        sum(p[0] for p in left_eye) / len(left_eye),
        sum(p[1] for p in left_eye) / len(left_eye),
    )
    right_eye_center = (
        sum(p[0] for p in right_eye) / len(right_eye),
        sum(p[1] for p in right_eye) / len(right_eye),
    )
    inter_ocular = _dist(left_eye_center, right_eye_center)
    if inter_ocular == 0:
        return None

    mouth_width = _dist(top_lip[0], top_lip[6])  # cantos da boca (indices 0 e 6 do top_lip)
    smile_ratio = mouth_width / inter_ocular

    nose_bridge = landmarks.get("nose_bridge") or landmarks.get("nose_tip")
    turn_ratio = 0.5
    if nose_bridge:
        nose_x = nose_bridge[-1][0]
        span = right_eye_center[0] - left_eye_center[0]
        if span != 0:
            turn_ratio = (nose_x - left_eye_center[0]) / span

    return {"ear": ear, "smile_ratio": smile_ratio, "turn_ratio": turn_ratio}


def verify_challenge_sequence(
    action: ChallengeAction, frames_base64: list[str]
) -> tuple[bool, dict]:
    """Verifica se a sequência de frames mostra a acção pedida a acontecer de facto.

    Devolve (passou: bool, detalhes: dict) — detalhes inclui as métricas usadas,
    úteis para diagnóstico/auditoria em caso de rejeição.
    """
    if not FACE_RECOGNITION_AVAILABLE:
        return False, {"reason": "face_recognition_unavailable"}

    if len(frames_base64) < _MIN_FRAMES:
        return False, {"reason": "frames_insuficientes", "recebidos": len(frames_base64)}

    metrics_per_frame: list[dict[str, float]] = []
    for frame in frames_base64[:_MAX_FRAMES]:
        landmarks = _extract_landmarks(frame)
        if landmarks is None:
            continue
        m = _frame_metrics(landmarks)
        if m is not None:
            metrics_per_frame.append(m)

    if len(metrics_per_frame) < _MIN_FRAMES:
        return False, {
            "reason": "rosto_nao_detectado_em_frames_suficientes",
            "frames_com_rosto": len(metrics_per_frame),
        }

    if action == ChallengeAction.BLINK:
        ear_values = [m["ear"] for m in metrics_per_frame]
        min_ear = min(ear_values)
        max_ear = max(ear_values)
        blinked = min_ear < _EAR_BLINK_DROP and max_ear > _EAR_OPEN_MIN
        return blinked, {"ear_values": ear_values, "min_ear": min_ear, "max_ear": max_ear}

    if action == ChallengeAction.SMILE:
        ratios = [m["smile_ratio"] for m in metrics_per_frame]
        baseline = min(ratios[: max(1, len(ratios) // 3)])  # media do inicio como neutro
        peak = max(ratios)
        increase = (peak - baseline) / baseline if baseline > 0 else 0.0
        smiled = increase >= _SMILE_RATIO_INCREASE
        return smiled, {"smile_ratios": ratios, "baseline": baseline, "peak": peak, "increase": increase}

    if action == ChallengeAction.TURN_HEAD:
        turns = [m["turn_ratio"] for m in metrics_per_frame]
        baseline = turns[0]
        max_dev = max(abs(t - baseline) for t in turns)
        turned = max_dev >= _TURN_DEVIATION_MIN
        return turned, {"turn_ratios": turns, "baseline": baseline, "max_deviation": max_dev}

    return False, {"reason": "acao_desconhecida"}
