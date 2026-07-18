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

A detecção da acção usa o MediaPipe FaceLandmarker (478 pontos), um modelo
separado do FaceDetector usado em `services/biometric.py` — este precisa de
geometria fina (contorno dos olhos, cantos da boca) que os 6 keypoints do
detector não fornecem. Os índices dos pontos usados abaixo (olhos, boca,
nariz) foram verificados empiricamente sobre o mapa canónico do Face Mesh.
"""

import logging
import math
import time
import uuid
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

from app.services.biometric import _base64_to_numpy

log = logging.getLogger("faceclock.liveness_challenge")

_MODELS_DIR = Path(__file__).resolve().parent.parent / "ml_models"
_FACE_LANDMARKER_MODEL_PATH = _MODELS_DIR / "face_landmarker.task"

try:
    import mediapipe as mp
    from mediapipe.tasks.python import BaseOptions
    from mediapipe.tasks.python.vision import FaceLandmarker, FaceLandmarkerOptions, RunningMode

    MEDIAPIPE_LANDMARKER_AVAILABLE = _FACE_LANDMARKER_MODEL_PATH.is_file()
    if not MEDIAPIPE_LANDMARKER_AVAILABLE:
        log.warning(
            "Modelo MediaPipe em falta (%s) — prova de vida por accao desativada",
            _FACE_LANDMARKER_MODEL_PATH,
        )
except ImportError:
    MEDIAPIPE_LANDMARKER_AVAILABLE = False
    log.warning("mediapipe nao disponivel — prova de vida por accao desativada")

# Índices do MediaPipe Face Mesh (478 pontos), verificados empiricamente.
# Cada lista de olho segue a ordem p1..p6 do EAR clássico (Soukupová & Čech):
# p1/p4 = cantos (eixo horizontal), p2/p3 = pálpebra superior, p5/p6 = inferior.
_EYE_A_IDX = [33, 160, 158, 133, 153, 144]
_EYE_B_IDX = [362, 385, 387, 263, 373, 380]
_MOUTH_LEFT_IDX = 61
_MOUTH_RIGHT_IDX = 291
_NOSE_TIP_IDX = 4

_landmarker: "FaceLandmarker | None" = None


def _get_landmarker() -> "FaceLandmarker":
    global _landmarker
    if _landmarker is None:
        if not MEDIAPIPE_LANDMARKER_AVAILABLE:
            raise RuntimeError("mediapipe nao instalado ou modelo em falta")
        options = FaceLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=str(_FACE_LANDMARKER_MODEL_PATH)),
            running_mode=RunningMode.IMAGE,
            num_faces=1,
        )
        _landmarker = FaceLandmarker.create_from_options(options)
        log.info("MediaPipe FaceLandmarker carregado (prova de vida por accao).")
    return _landmarker


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


def _extract_landmark_points(image_base64: str) -> "list[tuple[float, float]] | None":
    """Devolve os 478 pontos (em pixeis) do primeiro rosto detectado pelo
    MediaPipe FaceLandmarker, ou None se não houver rosto ou o modelo não
    estiver disponível."""
    if not MEDIAPIPE_LANDMARKER_AVAILABLE:
        return None
    img = _base64_to_numpy(image_base64)
    if img is None:
        return None

    import cv2

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    height, width = img_rgb.shape[:2]
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)

    result = _get_landmarker().detect(mp_image)
    if not result.face_landmarks:
        return None

    landmarks = result.face_landmarks[0]
    return [(pt.x * width, pt.y * height) for pt in landmarks]


def _eye_aspect_ratio(eye_points: list[tuple[float, float]]) -> float | None:
    """EAR clássico (Soukupová & Čech): (|p2-p6| + |p3-p5|) / (2 * |p1-p4|)."""
    if len(eye_points) != 6:
        return None
    p1, p2, p3, p4, p5, p6 = eye_points
    horizontal = _dist(p1, p4)
    if horizontal == 0:
        return None
    return (_dist(p2, p6) + _dist(p3, p5)) / (2.0 * horizontal)


def _frame_metrics(points: "list[tuple[float, float]]") -> "dict[str, float] | None":
    """Extrai as métricas usadas pelos 3 desafios a partir dos 478 pontos MediaPipe."""
    try:
        eye_a = [points[i] for i in _EYE_A_IDX]
        eye_b = [points[i] for i in _EYE_B_IDX]
        mouth_left = points[_MOUTH_LEFT_IDX]
        mouth_right = points[_MOUTH_RIGHT_IDX]
        nose_tip = points[_NOSE_TIP_IDX]
    except IndexError:
        return None

    ear_a = _eye_aspect_ratio(eye_a)
    ear_b = _eye_aspect_ratio(eye_b)
    if ear_a is None or ear_b is None:
        return None
    ear = (ear_a + ear_b) / 2.0

    eye_a_center = (
        sum(p[0] for p in eye_a) / len(eye_a),
        sum(p[1] for p in eye_a) / len(eye_a),
    )
    eye_b_center = (
        sum(p[0] for p in eye_b) / len(eye_b),
        sum(p[1] for p in eye_b) / len(eye_b),
    )
    inter_ocular = _dist(eye_a_center, eye_b_center)
    if inter_ocular == 0:
        return None

    mouth_width = _dist(mouth_left, mouth_right)
    smile_ratio = mouth_width / inter_ocular

    turn_ratio = 0.5
    span = eye_b_center[0] - eye_a_center[0]
    if span != 0:
        turn_ratio = (nose_tip[0] - eye_a_center[0]) / span

    return {"ear": ear, "smile_ratio": smile_ratio, "turn_ratio": turn_ratio}


def verify_challenge_sequence(
    action: ChallengeAction, frames_base64: list[str]
) -> tuple[bool, dict]:
    """Verifica se a sequência de frames mostra a acção pedida a acontecer de facto.

    Devolve (passou: bool, detalhes: dict) — detalhes inclui as métricas usadas,
    úteis para diagnóstico/auditoria em caso de rejeição.
    """
    if not MEDIAPIPE_LANDMARKER_AVAILABLE:
        return False, {"reason": "mediapipe_unavailable"}

    if len(frames_base64) < _MIN_FRAMES:
        return False, {"reason": "frames_insuficientes", "recebidos": len(frames_base64)}

    metrics_per_frame: list[dict[str, float]] = []
    for frame in frames_base64[:_MAX_FRAMES]:
        points = _extract_landmark_points(frame)
        if points is None:
            continue
        m = _frame_metrics(points)
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
