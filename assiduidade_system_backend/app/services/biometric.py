"""
  Pipeline de reconhecimento facial em 3 etapas:

  ETAPA 1 — MediaPipe FaceDetector (BlazeFace short-range)
    Deteta a regiao do rosto e os keypoints dos olhos, nariz e boca num
    unico passe (modelo leve, ~230KB, optimizado para CPU/mobile — o mesmo
    modelo usado na app Android para o preview em tempo real).

  ETAPA 2 — Alinhamento (keypoints dos olhos do MediaPipe)
    Usa os dois keypoints dos olhos devolvidos pelo detector para calcular
    o angulo de inclinacao e aplicar warp affine, normalizando rotacao,
    escala e posicao. Resultado: crop de 160x160 px com face alinhada.

  ETAPA 3 — Modelo de Embedding configuravel (FaceNet/ArcFace/etc.)
    Converte o rosto alinhado num vetor denso, usando o modelo activo
    (default FaceNet InceptionResnetV1). Embeddings sao normalizados
    (norma L2 = 1) antes de armazenar.

Nota: `services/liveness_challenge.py` usa um modelo MediaPipe separado
(FaceLandmarker, 478 pontos) para a prova de vida activa (piscar/sorrir/
virar o rosto), que precisa de geometria mais fina do que os 6 keypoints
do detector usado aqui.
"""
import base64
import binascii
import json
import logging
import math
import os
from pathlib import Path

import cv2
import httpx
import numpy as np

from app.config import settings
from app.security import get_biometric_encryption
from app.services.face_detectors import get_face_detector

log = logging.getLogger(__name__)

_MODELS_DIR = Path(__file__).resolve().parent.parent / "ml_models"
_FACE_DETECTOR_MODEL_PATH = _MODELS_DIR / "blaze_face_short_range.tflite"

# ─── Etapa 1 + 2: MediaPipe FaceDetector (deteccao + keypoints dos olhos) ────
try:
    import mediapipe as mp
    from mediapipe.tasks.python import BaseOptions
    from mediapipe.tasks.python.vision import FaceDetector, FaceDetectorOptions, RunningMode

    MEDIAPIPE_AVAILABLE = _FACE_DETECTOR_MODEL_PATH.is_file()
    if not MEDIAPIPE_AVAILABLE:
        log.warning(
            "Modelo MediaPipe em falta (%s) — deteccao facial desativada",
            _FACE_DETECTOR_MODEL_PATH,
        )
except ImportError:
    MEDIAPIPE_AVAILABLE = False
    log.warning("mediapipe nao disponivel — deteccao facial desativada")

# ─── Etapa extra: MediaPipe FaceLandmarker (olhos abertos) ───────────────────
_FACE_LANDMARKER_MODEL_PATH = _MODELS_DIR / "face_landmarker.task"

try:
    from mediapipe.tasks.python.vision import FaceLandmarker, FaceLandmarkerOptions

    MEDIAPIPE_LANDMARKER_AVAILABLE = _FACE_LANDMARKER_MODEL_PATH.is_file()
    if not MEDIAPIPE_LANDMARKER_AVAILABLE:
        log.warning(
            "Modelo FaceLandmarker em falta (%s) — verificacao de olhos abertos desativada",
            _FACE_LANDMARKER_MODEL_PATH,
        )
except ImportError:
    MEDIAPIPE_LANDMARKER_AVAILABLE = False
    log.warning("mediapipe nao disponivel — verificacao de olhos abertos desativada")

# Índices MediaPipe Face Mesh para EAR (Soukupová & Čech).
_EYE_LEFT_IDX = [33, 160, 158, 133, 153, 144]
_EYE_RIGHT_IDX = [362, 385, 387, 263, 373, 380]
# EAR mínimo para considerar olhos abertos (calibrado por inspeção).
_EAR_OPEN_THRESHOLD = 0.28

_landmarker: "FaceLandmarker | None" = None

from app.services.embedding_models import get_embedding_model, FaceEmbeddingModel


# ─── Constantes ──────────────────────────────────────────────────────────────
QUALITY_THRESHOLD_FALLBACK = 0.55
_MIN_DETECTION_CONFIDENCE = 0.5

# ─── Singletons (lazy init) ──────────────────────────────────────────────────
_face_detector: "FaceDetector | None" = None
_embedding_model: "FaceEmbeddingModel | None" = None


def _get_embedding_model() -> "FaceEmbeddingModel":
    global _embedding_model
    if _embedding_model is None:
        _embedding_model = get_embedding_model()
    return _embedding_model


def _get_face_detector() -> "FaceDetector":
    global _face_detector
    if _face_detector is None:
        if not MEDIAPIPE_AVAILABLE:
            raise RuntimeError("mediapipe nao instalado ou modelo em falta")
        options = FaceDetectorOptions(
            base_options=BaseOptions(model_asset_path=str(_FACE_DETECTOR_MODEL_PATH)),
            running_mode=RunningMode.IMAGE,
            min_detection_confidence=_MIN_DETECTION_CONFIDENCE,
        )
        _face_detector = FaceDetector.create_from_options(options)
        log.info("MediaPipe FaceDetector (BlazeFace short-range) carregado.")
    return _face_detector


def warmup_biometric_models() -> None:
    """Carrega detector e modelo de embedding no arranque; producao nunca falha
    no 1.º pedido."""
    _get_face_detector()
    _get_embedding_model().warmup()

    # Detector/modelo pluggaveis (registries com cache propria em
    # face_detectors.py/liveness_models.py) — pre-carregar tambem, para que
    # YuNet/anti-spoofing nao paguem o custo de carregar o ONNX no 1.º pedido.
    # Ao contrario do caminho MediaPipe acima, nao deve derrubar o arranque
    # se o ficheiro configurado estiver em falta.
    from app.services.face_detectors import get_face_detector
    from app.services.liveness_models import get_liveness_model

    try:
        get_face_detector(settings.biometric_face_detector)
    except RuntimeError as exc:
        log.warning("Falha no pre-carregamento do detector de face: %s", exc)

    try:
        get_liveness_model(settings.liveness_model)
    except RuntimeError as exc:
        log.warning("Falha no pre-carregamento do modelo de liveness: %s", exc)


# ─── Utilidades de imagem ─────────────────────────────────────────────────────

def _decode_base64(image_base64: str) -> bytes:
    try:
        return base64.b64decode(image_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("invalid_base64") from exc


def _download_image(image_url: str) -> bytes:
    try:
        with httpx.Client(timeout=settings.image_download_timeout_seconds) as client:
            response = client.get(image_url)
            response.raise_for_status()
            data = response.content
            if len(data) > settings.image_download_max_bytes:
                raise ValueError("image_too_large")
            return data
    except httpx.HTTPError as exc:
        log.warning("Falha ao descarregar imagem de %s: %s", image_url, exc)
        raise ValueError("image_download_failed") from exc


def _resolve_image_bytes(image_base64: str | None, image_url: str | None) -> bytes:
    if image_url:
        return _download_image(image_url)
    if image_base64:
        return _decode_base64(image_base64)
    raise ValueError("no_image_source")


def _bytes_to_numpy(image_bytes: bytes) -> "np.ndarray | None":
    """Decodifica bytes de imagem (JPEG/PNG) para array OpenCV (BGR)."""
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None


# Mantido para compatibilidade com chamadas legadas.
def _base64_to_numpy(image_base64: str) -> "np.ndarray | None":
    """Decodifica base64 para array OpenCV (BGR)."""
    try:
        raw = _decode_base64(image_base64)
        return _bytes_to_numpy(raw)
    except Exception:
        return None


# ─── ETAPA 1: Deteccao de rosto (MediaPipe BlazeFace) ────────────────────────

class _Detection:
    """Uma deteccao facial do MediaPipe: caixa delimitadora + keypoints dos olhos."""

    __slots__ = ("x", "y", "w", "h", "score", "eye_a", "eye_b")

    def __init__(self, x: int, y: int, w: int, h: int, score: float,
                 eye_a: "tuple[float, float] | None", eye_b: "tuple[float, float] | None"):
        self.x, self.y, self.w, self.h = x, y, w, h
        self.score = score
        self.eye_a = eye_a
        self.eye_b = eye_b


def _detect_faces(img_bgr: "np.ndarray") -> list[_Detection]:
    """
    Localiza rostos na imagem usando o detector configurado.

    Os dois primeiros keypoints devolvidos pelo detector sao usados como olhos
    para o alinhamento da Etapa 2.

    Retorna lista ordenada por area (maior primeiro).
    """
    detector = get_face_detector()
    height, width = img_bgr.shape[:2]
    results = detector.detect(img_bgr)

    detections = []
    for r in results:
        x = int(r.bbox[0] * width)
        y = int(r.bbox[1] * height)
        w = int(r.bbox[2] * width)
        h = int(r.bbox[3] * height)
        kps = r.keypoints or []
        eye_a = (kps[0][0] * width, kps[0][1] * height) if len(kps) > 0 else None
        eye_b = (kps[1][0] * width, kps[1][1] * height) if len(kps) > 1 else None
        detections.append(_Detection(x, y, w, h, r.confidence, eye_a, eye_b))

    detections.sort(key=lambda f: f.w * f.h, reverse=True)
    return detections


def _require_single_face(img_bgr: "np.ndarray") -> list[_Detection]:
    """Requer exactamente uma face na imagem; levanta ValueError se houver
    zero ou multiplas faces. Usado em enrollment e verify para evitar
    ambiguidade e ataques com duas faces."""
    faces = _detect_faces(img_bgr)
    if not faces:
        raise ValueError("nenhuma_face_detectada")
    if len(faces) > 1:
        raise ValueError("multiplas_faces_detectadas")
    return faces


def _get_landmarker() -> "FaceLandmarker":
    global _landmarker
    if _landmarker is None:
        if not MEDIAPIPE_LANDMARKER_AVAILABLE:
            raise RuntimeError("mediapipe FaceLandmarker nao instalado ou modelo em falta")
        options = FaceLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=str(_FACE_LANDMARKER_MODEL_PATH)),
            running_mode=RunningMode.IMAGE,
            num_faces=1,
        )
        _landmarker = FaceLandmarker.create_from_options(options)
        log.info("MediaPipe FaceLandmarker carregado (qualidade de olhos).")
    return _landmarker


def _eye_aspect_ratio(eye_points: list[tuple[float, float]]) -> float | None:
    if len(eye_points) != 6:
        return None
    p1, p2, p3, p4, p5, p6 = eye_points
    horizontal = math.hypot(p1[0] - p4[0], p1[1] - p4[1])
    if horizontal == 0:
        return None
    return (math.hypot(p2[0] - p6[0], p2[1] - p6[1]) +
            math.hypot(p3[0] - p5[0], p3[1] - p5[1])) / (2.0 * horizontal)


def are_eyes_open(image_base64: str | None = None, image_url: str | None = None) -> bool:
    """Verifica se ambos os olhos estão abertos usando FaceLandmarker + EAR.

    Retorna True se abertos, False se fechados/ausentes, e True também se o
    modelo não estiver disponível (fail-open para não bloquear enrollment).
    """
    if not MEDIAPIPE_LANDMARKER_AVAILABLE:
        return True

    try:
        image_bytes = _resolve_image_bytes(image_base64, image_url)
    except ValueError:
        return False

    img = _bytes_to_numpy(image_bytes)
    if img is None:
        return False

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    height, width = img_rgb.shape[:2]
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)

    try:
        result = _get_landmarker().detect(mp_image)
    except Exception:
        return True  # fail-open

    if not result.face_landmarks:
        return False

    landmarks = result.face_landmarks[0]
    points = [(pt.x * width, pt.y * height) for pt in landmarks]

    try:
        left_eye = [points[i] for i in _EYE_LEFT_IDX]
        right_eye = [points[i] for i in _EYE_RIGHT_IDX]
    except IndexError:
        return False

    left_ear = _eye_aspect_ratio(left_eye)
    right_ear = _eye_aspect_ratio(right_eye)
    if left_ear is None or right_ear is None:
        return False

    return left_ear >= _EAR_OPEN_THRESHOLD and right_ear >= _EAR_OPEN_THRESHOLD


# Índices MediaPipe Face Mesh para estimativa de pose (modelo canónico 3D).
_POSE_LANDMARK_IDX = {
    "nose": 4,
    "chin": 152,
    "left_eye_outer": 33,
    "right_eye_outer": 362,
    "left_mouth": 61,
    "right_mouth": 291,
}

# Modelo canónico da face em milímetros (aproximado).
_FACE_MODEL_POINTS = np.array(
    [
        [0.0, 0.0, 0.0],        # nose
        [0.0, -330.0, -65.0],   # chin
        [-225.0, 170.0, -135.0],  # left eye outer
        [225.0, 170.0, -135.0],   # right eye outer
        [-150.0, -150.0, -125.0],  # left mouth
        [150.0, -150.0, -125.0],   # right mouth
    ],
    dtype=np.float32,
)


def _estimate_head_pose(image_points: "np.ndarray") -> "tuple[float, float, float] | None":
    """Estima yaw, pitch e roll usando razões geométricas simples.

    Esta aproximação é suficiente para rejeitar poses extremas em enrollment e
    verify. Não substitui um estimador PnP calibrado, mas é robusta e não
    depende de parâmetros intrínsecos da câmara.

    Retorna (yaw, pitch, roll) em graus ou None se faltarem pontos.
    """
    if image_points.shape[0] != 6:
        return None

    nose = image_points[0]
    chin = image_points[1]
    left_eye = image_points[2]
    right_eye = image_points[3]
    left_mouth = image_points[4]
    right_mouth = image_points[5]

    # Roll: inclinação da linha dos olhos.
    dx = right_eye[0] - left_eye[0]
    dy = right_eye[1] - left_eye[1]
    roll = math.degrees(math.atan2(dy, dx))

    # Yaw aproximado: diferença relativa entre distâncias nariz-olho.
    d_left = math.hypot(nose[0] - left_eye[0], nose[1] - left_eye[1])
    d_right = math.hypot(nose[0] - right_eye[0], nose[1] - right_eye[1])
    avg_eye_dist = (d_left + d_right) / 2.0
    yaw = 0.0
    if avg_eye_dist > 0:
        yaw = math.degrees(math.asin(max(-1.0, min(1.0, (d_right - d_left) / avg_eye_dist))))

    # Pitch aproximado: posição relativa do queixo em relação aos olhos.
    eye_y = (left_eye[1] + right_eye[1]) / 2.0
    face_height = abs(chin[1] - eye_y)
    mouth_y = (left_mouth[1] + right_mouth[1]) / 2.0
    if face_height > 0:
        # Razão queixo-boca / olho-boca. Quando a cabeça vira para cima, o
        # queixo aproxima-se da boca (razão diminui); para baixo, afasta-se.
        eye_to_mouth = abs(mouth_y - eye_y)
        chin_to_mouth = abs(chin[1] - mouth_y)
        ratio = chin_to_mouth / (eye_to_mouth + 1e-6)
        # Razão frontal típica: ~0.8-1.2. Mapear para graus aproximados.
        pitch = (ratio - 1.0) * 45.0
        pitch = max(-45.0, min(45.0, pitch))
    else:
        pitch = 0.0

    return yaw, pitch, roll


def assess_pose_and_occlusion(
    image_base64: str | None = None,
    image_url: str | None = None,
) -> tuple[bool, str | None]:
    """Verifica pose frontal e oclusão usando FaceLandmarker.

    Retorna (ok, reason). Se o landmarker não estiver disponível, devolve
    (True, None) para não bloquear enrollment em ambientes sem modelo.
    """
    if not MEDIAPIPE_LANDMARKER_AVAILABLE:
        return True, None

    try:
        image_bytes = _resolve_image_bytes(image_base64, image_url)
    except ValueError:
        return False, "invalid_image"

    img = _bytes_to_numpy(image_bytes)
    if img is None:
        return False, "invalid_image"

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    height, width = img_rgb.shape[:2]
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)

    try:
        result = _get_landmarker().detect(mp_image)
    except Exception:
        return True, None  # fail-open

    if not result.face_landmarks:
        return False, "no_face_detected"

    landmarks = result.face_landmarks[0]
    points = [(pt.x * width, pt.y * height) for pt in landmarks]

    # Verificar se pontos críticos estão dentro da imagem (oclusão parcial).
    for name, idx in _POSE_LANDMARK_IDX.items():
        try:
            x, y = points[idx]
        except IndexError:
            return False, f"occluded_{name}"
        if x < 0 or x > width or y < 0 or y > height:
            return False, f"occluded_{name}"

    image_points = np.array(
        [points[idx] for idx in _POSE_LANDMARK_IDX.values()],
        dtype=np.float32,
    )

    pose = _estimate_head_pose(image_points)
    if pose is None:
        return True, None  # fail-open se não conseguir estimar

    yaw, pitch, roll = pose
    if abs(yaw) > settings.biometric_max_yaw:
        return False, f"excessive_yaw_{yaw:.1f}"
    if abs(pitch) > settings.biometric_max_pitch:
        return False, f"excessive_pitch_{pitch:.1f}"
    if abs(roll) > settings.biometric_max_roll:
        return False, f"excessive_roll_{roll:.1f}"

    return True, None


# ─── ETAPA 2: Alinhamento facial (keypoints dos olhos do MediaPipe) ──────────

def _align_face(
    img_rgb: "np.ndarray",
    eye_a: "tuple[float, float]",
    eye_b: "tuple[float, float]",
    output_size: int,
) -> "np.ndarray | None":
    """
    Normaliza o rosto usando os dois keypoints dos olhos devolvidos pelo
    MediaPipe FaceDetector.

    1. Calcula o angulo de inclinacao entre os dois olhos
    2. Aplica rotacao + escala via warpAffine
    3. Recorta a regiao facial no tamanho esperado pelo modelo activo

    Retorna imagem RGB alinhada ou None em caso de falha.
    """
    try:
        left_center = np.array(eye_a, dtype=np.float32)
        right_center = np.array(eye_b, dtype=np.float32)

        # Angulo de inclinacao
        dy = float(right_center[1] - left_center[1])
        dx = float(right_center[0] - left_center[0])
        angle = float(np.degrees(np.arctan2(dy, dx)))

        # Centro de rotacao: ponto medio entre os olhos
        eye_center = ((left_center + right_center) / 2.0).astype(np.float32)

        # Escala para distancia padrao entre olhos
        eye_dist = float(np.linalg.norm(right_center - left_center))
        desired_dist = output_size * 0.45
        scale = desired_dist / eye_dist if eye_dist > 0 else 1.0

        # Matriz affine: rotacao + escala
        M = cv2.getRotationMatrix2D(tuple(eye_center), angle, scale)

        # Translacao para centrar o rosto no output
        M[0, 2] += output_size * 0.5 - eye_center[0]
        M[1, 2] += output_size * 0.4 - eye_center[1]

        aligned = cv2.warpAffine(
            img_rgb, M,
            (output_size, output_size),
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REPLICATE,
        )
        return aligned
    except Exception:
        return None


def _extract_aligned_face(img_bgr: "np.ndarray") -> "np.ndarray | None":
    """
    Executa Etapa 1 + Etapa 2:
      MediaPipe deteta o rosto e os keypoints dos olhos → alinha o crop.

    Retorna array RGB no tamanho esperado pelo modelo activo ou None se falhar.
    """
    faces = _require_single_face(img_bgr)
    face = faces[0]

    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    output_size = _get_embedding_model().input_size()

    if face.eye_a is not None and face.eye_b is not None:
        aligned = _align_face(img_rgb, face.eye_a, face.eye_b, output_size)
        if aligned is not None:
            return aligned

    # Fallback sem alinhamento: recorta a caixa delimitadora e redimensiona
    x, y = max(face.x, 0), max(face.y, 0)
    face_crop = img_rgb[y:y + face.h, x:x + face.w]
    if face_crop.size == 0:
        return None
    return cv2.resize(face_crop, (output_size, output_size), interpolation=cv2.INTER_CUBIC)


# ─── ETAPA 3: Embedding via modelo configurado ───────────────────────────────

def _embed_with_model(face_rgb: "np.ndarray") -> list[float]:
    """Gera embedding usando o modelo activo (FaceNet, ArcFace, etc.)."""
    model = _get_embedding_model()
    return model.embed(face_rgb)


# ─── API publica do servico ───────────────────────────────────────────────────

def _has_face_landmarks(img_bgr: "np.ndarray") -> tuple[bool, list[dict], str | None]:
    """Deteta rostos e devolve info usada na avaliacao de qualidade.

    Retorna (success, landmarks_info, reason). reason é preenchida quando
    nenhuma face ou multiplas faces sao detectadas.
    """
    if not MEDIAPIPE_AVAILABLE:
        return True, [{
            "feature_count": 6,
            "has_nose_bridge": True,
            "has_eye_regions": True,
            "score": 1.0,
        }], None

    try:
        faces = _require_single_face(img_bgr)
    except ValueError as exc:
        return False, [], str(exc)

    landmarks_info = [
        {
            "feature_count": 6,
            "has_nose_bridge": True,
            "has_eye_regions": f.eye_a is not None and f.eye_b is not None,
            "score": f.score,
        }
        for f in faces
    ]
    return True, landmarks_info, None


def assess_capture_quality(
    image_base64: str | None = None,
    image_url: str | None = None,
) -> tuple[float, "str | None"]:
    """
    Avalia qualidade da captura:
    - Detecao de face (MediaPipe)
    - Nitidez via Laplaciano
    - Iluminacao via histograma
    - Tamanho relativo do rosto
    """
    try:
        image_bytes = _resolve_image_bytes(image_base64, image_url)
    except ValueError as exc:
        log.warning("Falha ao obter bytes da imagem: %s", exc)
        return 0.0, "invalid_image"

    img = _bytes_to_numpy(image_bytes)
    if img is None:
        return 0.0, "invalid_image"

    height, width = img.shape[:2]
    if height < 100 or width < 100:
        return 0.1, "image_too_small"

    face_detected, landmarks_info, face_reason = _has_face_landmarks(img)
    if not face_detected:
        return 0.15, face_reason or "no_face_detected"

    if not are_eyes_open(image_base64, image_url):
        return 0.18, "eyes_closed"

    pose_ok, pose_reason = assess_pose_and_occlusion(image_base64, image_url)
    if not pose_ok:
        return 0.16, pose_reason or "invalid_pose"

    sharpness = _compute_sharpness(img)
    brightness, brightness_ok = _compute_brightness(img)
    face_size_score = _compute_face_size_score(img)

    quality = round(
        (sharpness * 0.35)
        + (0.2 if brightness_ok else 0.05)
        + (face_size_score * 0.35)
        + (0.1 if landmarks_info and landmarks_info[0].get("has_eye_regions") else 0.0),
        4,
    )

    if quality < 0.25:
        reason = "low_quality_capture"
        if sharpness < 0.3:
            reason = "blurry_capture"
        elif not brightness_ok:
            reason = "poor_lighting"
        elif face_size_score < 0.3:
            reason = "face_too_small"
        return quality, reason

    return quality, None


def _compute_sharpness(img_bgr: "np.ndarray") -> float:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    return min(cv2.Laplacian(gray, cv2.CV_64F).var() / 500.0, 1.0)


def _compute_brightness(img_bgr: "np.ndarray") -> tuple[float, bool]:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    mean_brightness = float(np.mean(gray))
    normalized = min(max(mean_brightness / 128.0, 0.0), 1.0)
    return normalized, 40 < mean_brightness < 200


def _compute_face_size_score(img_bgr: "np.ndarray") -> float:
    """Score baseado no tamanho relativo do rosto."""
    faces = _require_single_face(img_bgr)

    height, width = img_bgr.shape[:2]
    image_area = height * width
    ideal_ratio = 0.15

    face = faces[0]
    return round(max(0.0, 1.0 - abs((face.w * face.h / image_area) - ideal_ratio) / ideal_ratio), 4)


from app.services.liveness_models import get_liveness_model


def estimate_liveness(
    image_base64: str | None = None,
    image_url: str | None = None,
    quality_score: "float | None" = None,
) -> float:
    """
    Estima liveness usando o modelo configurado (default: heuristica).
    """
    try:
        image_bytes = _resolve_image_bytes(image_base64, image_url)
    except ValueError as exc:
        log.warning("Falha ao obter bytes da imagem: %s", exc)
        return 0.0

    img = _bytes_to_numpy(image_bytes)
    if img is None:
        return 0.0

    face_detected, _, _ = _has_face_landmarks(img)
    if not face_detected:
        return 0.0

    liveness_model = get_liveness_model()
    base_score = liveness_model.score(img)
    # Combinar com qualidade da imagem (15% de peso) para manter compatibilidade
    # comportamental com a heuristica anterior.
    combined = (base_score * 0.85) + ((quality_score or 0.5) * 0.15)
    return round(min(combined, 1.0), 4)


def build_embedding(
    image_base64: str | None = None,
    image_url: str | None = None,
) -> list[float]:
    """
    Pipeline completo de 3 etapas:
      1. MediaPipe BlazeFace  -> detetar rosto + keypoints dos olhos
      2. Alinhamento          -> normalizar rotacao/escala
      3. Modelo activo        -> embedding normalizado
    """
    model = _get_embedding_model()

    try:
        image_bytes = _resolve_image_bytes(image_base64, image_url)
    except ValueError as exc:
        log.warning("Falha ao obter bytes da imagem: %s", exc)
        raise ValueError("invalid_image") from exc

    img = _bytes_to_numpy(image_bytes)
    if img is None:
        raise ValueError("invalid_image")

    # Etapas 1 + 2: deteccao + alinhamento
    aligned_face = _extract_aligned_face(img)
    if aligned_face is None:
        raise ValueError("no_face_detected")

    # Etapa 3: embedding via modelo configurado
    return model.embed(aligned_face)


def _get_cancelable_transform() -> "CancelableTransform | None":
    from app.security.cancelable_transform import CancelableTransform

    if settings.cancelable_transform_secret:
        return CancelableTransform(
            settings.cancelable_transform_secret,
            settings.cancelable_transform_version,
        )
    return None


def apply_cancelable_transform(embedding: list[float]) -> tuple[list[float], str | None]:
    """Aplica transformacao cancelavel se configurada. Devolve (embedding, version)."""
    transform = _get_cancelable_transform()
    if transform is None:
        return embedding, None
    return transform.transform(embedding), transform.version


def average_embeddings(embeddings: list[list[float]]) -> list[float]:
    """Media de multiplos embeddings com normalizacao L2."""
    if not embeddings:
        raise ValueError("no_embeddings")
    dim = len(embeddings[0])
    combined = [sum(emb[i] for emb in embeddings) / len(embeddings) for i in range(dim)]
    return _normalize_vector(combined)


def serialize_embedding(embedding: list[float]) -> bytes:
    """Serializa e encripta o embedding facial antes de persistir."""
    plaintext = json.dumps(embedding, separators=(",", ":")).encode("utf-8")
    return get_biometric_encryption().encrypt(plaintext)


def deserialize_embedding(blob: bytes) -> list[float]:
    """Desencripta (se necessario) e desserializa o embedding facial."""
    try:
        plaintext = get_biometric_encryption().decrypt(blob)
        return [float(v) for v in json.loads(plaintext.decode("utf-8"))]
    except (json.JSONDecodeError, UnicodeDecodeError, ValueError):
        raise ValueError("invalid_embedding_data")


def cosine_similarity(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(x * x for x in b))
    if na == 0 or nb == 0:
        return 0.0
    return round(dot / (na * nb), 4)


def _normalize_vector(vector: list[float]) -> list[float]:
    norm = math.sqrt(sum(v * v for v in vector))
    if norm == 0:
        return vector
    return [v / norm for v in vector]
