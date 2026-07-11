"""
Pipeline de reconhecimento facial em 3 etapas:

  ETAPA 1 — OpenCV (Detecao)
    Decodifica a imagem e detecta regioes de rosto via Haar Cascade
    com equalizacao de histograma para robustez em diferentes iluminacoes.

  ETAPA 2 — Dlib / face_recognition (Alinhamento)
    Extrai 68 landmarks faciais, calcula o angulo dos olhos e aplica
    warp affine para normalizar rotacao, escala e posicao.
    Resultado: crop de 160x160 px com face canonicamente alinhada.

  ETAPA 3 — FaceNet / InceptionResnetV1 (Embedding)
    Converte o rosto alinhado num vetor de 512 dimensoes,
    usando o modelo InceptionResnetV1 pre-treinado no dataset VGGFace2.
    Embeddings sao normalizados (norma L2 = 1) antes de armazenar.
"""
import base64
import binascii
import json
import math
import logging

import cv2
import numpy as np

log = logging.getLogger(__name__)

# ─── Etapa 2: Dlib via face_recognition ─────────────────────────────────────
try:
    import face_recognition
    FACE_RECOGNITION_AVAILABLE = True
except ImportError:
    FACE_RECOGNITION_AVAILABLE = False
    log.warning("face_recognition nao disponivel — alinhamento facial desativado")

# ─── Etapa 3: FaceNet via facenet-pytorch ────────────────────────────────────
try:
    import torch
    from facenet_pytorch import InceptionResnetV1
    FACENET_AVAILABLE = True
except ImportError:
    FACENET_AVAILABLE = False
    log.warning("facenet-pytorch nao disponivel — embeddings simulados ativos")


# ─── Constantes ──────────────────────────────────────────────────────────────
EMBEDDING_DIM = 512          # InceptionResnetV1 (VGGFace2)
MODEL_VERSION = "facenet-vggface2-v1"
QUALITY_THRESHOLD_FALLBACK = 0.55
_FACE_INPUT_SIZE = 160       # Dimensao esperada pelo FaceNet
_HAAR_MIN_FACE_PX = 60       # Rosto minimo para Haar Cascade

# ─── Singletons (lazy init) ──────────────────────────────────────────────────
_haar_cascade: "cv2.CascadeClassifier | None" = None
_facenet_model: "InceptionResnetV1 | None" = None


def _get_haar_cascade() -> "cv2.CascadeClassifier":
    global _haar_cascade
    if _haar_cascade is None:
        path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
        _haar_cascade = cv2.CascadeClassifier(path)
    return _haar_cascade


def _get_facenet() -> "InceptionResnetV1":
    global _facenet_model
    if _facenet_model is None:
        if not FACENET_AVAILABLE:
            raise RuntimeError("facenet-pytorch nao instalado")
        _facenet_model = InceptionResnetV1(pretrained="vggface2").eval()
        log.info("FaceNet InceptionResnetV1 (VGGFace2) carregado.")
    return _facenet_model


# ─── Utilidades de imagem ─────────────────────────────────────────────────────

def _decode_base64(image_base64: str) -> bytes:
    try:
        return base64.b64decode(image_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("invalid_base64") from exc


def _base64_to_numpy(image_base64: str) -> "np.ndarray | None":
    """Decodifica base64 para array OpenCV (BGR)."""
    try:
        raw = _decode_base64(image_base64)
        nparr = np.frombuffer(raw, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None


# ─── ETAPA 1: Detecao de rosto (OpenCV Haar Cascade) ─────────────────────────

def _detect_faces_opencv(img_bgr: "np.ndarray") -> list[tuple[int, int, int, int]]:
    """
    Localiza rostos na imagem usando OpenCV Haar Cascade.

    1. Converte para escala de cinza
    2. Equaliza histograma (melhora contraste e iluminacao)
    3. Detecta rostos e ordena por area (maior primeiro)

    Retorna lista de (x, y, w, h).
    """
    cascade = _get_haar_cascade()
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    gray = cv2.equalizeHist(gray)

    detections = cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(_HAAR_MIN_FACE_PX, _HAAR_MIN_FACE_PX),
        flags=cv2.CASCADE_SCALE_IMAGE,
    )

    if len(detections) == 0:
        return []

    faces = list(detections)
    faces.sort(key=lambda f: int(f[2]) * int(f[3]), reverse=True)
    return [(int(x), int(y), int(w), int(h)) for (x, y, w, h) in faces]


def _opencv_box_to_dlib_location(
    x: int, y: int, w: int, h: int
) -> tuple[int, int, int, int]:
    """Converte (x, y, w, h) do OpenCV para (top, right, bottom, left) do dlib."""
    return (y, x + w, y + h, x)


# ─── ETAPA 2: Alinhamento facial (Dlib landmarks) ────────────────────────────

def _align_face(img_rgb: "np.ndarray", face_landmarks: dict) -> "np.ndarray | None":
    """
    Normaliza o rosto usando os landmarks dos olhos (dlib 68-pontos).

    1. Calcula centroide do olho esquerdo e direito
    2. Calcula angulo de inclinacao entre os olhos
    3. Aplica rotacao + escala via warpAffine
    4. Recorta a regiao facial em _FACE_INPUT_SIZE x _FACE_INPUT_SIZE px

    Retorna imagem RGB alinhada ou None se landmarks insuficientes.
    """
    try:
        left_eye_pts = np.array(face_landmarks.get("left_eye", []), dtype=np.float32)
        right_eye_pts = np.array(face_landmarks.get("right_eye", []), dtype=np.float32)

        if len(left_eye_pts) == 0 or len(right_eye_pts) == 0:
            return None

        left_center = left_eye_pts.mean(axis=0)
        right_center = right_eye_pts.mean(axis=0)

        # Angulo de inclinacao
        dy = float(right_center[1] - left_center[1])
        dx = float(right_center[0] - left_center[0])
        angle = float(np.degrees(np.arctan2(dy, dx)))

        # Centro de rotacao: ponto medio entre os olhos
        eye_center = ((left_center + right_center) / 2.0).astype(np.float32)

        # Escala para distancia padrao entre olhos
        eye_dist = float(np.linalg.norm(right_center - left_center))
        desired_dist = _FACE_INPUT_SIZE * 0.45
        scale = desired_dist / eye_dist if eye_dist > 0 else 1.0

        # Matriz affine: rotacao + escala
        M = cv2.getRotationMatrix2D(tuple(eye_center), angle, scale)

        # Translacao para centrar o rosto no output
        M[0, 2] += _FACE_INPUT_SIZE * 0.5 - eye_center[0]
        M[1, 2] += _FACE_INPUT_SIZE * 0.4 - eye_center[1]

        aligned = cv2.warpAffine(
            img_rgb, M,
            (_FACE_INPUT_SIZE, _FACE_INPUT_SIZE),
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REPLICATE,
        )
        return aligned
    except Exception:
        return None


def _extract_aligned_face(img_bgr: "np.ndarray") -> "np.ndarray | None":
    """
    Executa Etapa 1 + Etapa 2:
      OpenCV detecta o rosto → Dlib alinha via landmarks.

    Retorna array RGB 160x160 ou None se falhar.
    """
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

    # Etapa 1: Detetar rosto com OpenCV
    faces = _detect_faces_opencv(img_bgr)
    if not faces:
        # Fallback: tenta dlib HOG se disponivel
        if FACE_RECOGNITION_AVAILABLE:
            dlib_locs = face_recognition.face_locations(img_rgb, model="hog")
            if not dlib_locs:
                return None
            top, right, bottom, left = dlib_locs[0]
            faces = [(left, top, right - left, bottom - top)]
        else:
            return None

    x, y, w, h = faces[0]

    if FACE_RECOGNITION_AVAILABLE:
        # Etapa 2: Alinhamento via landmarks dlib
        dlib_loc = [_opencv_box_to_dlib_location(x, y, w, h)]
        landmarks_list = face_recognition.face_landmarks(img_rgb, dlib_loc)
        if landmarks_list:
            aligned = _align_face(img_rgb, landmarks_list[0])
            if aligned is not None:
                return aligned

    # Fallback sem alinhamento: recorta e redimensiona o rosto
    face_crop = img_rgb[y:y + h, x:x + w]
    if face_crop.size == 0:
        return None
    return cv2.resize(face_crop, (_FACE_INPUT_SIZE, _FACE_INPUT_SIZE), interpolation=cv2.INTER_CUBIC)


# ─── ETAPA 3: Embedding FaceNet (InceptionResnetV1) ──────────────────────────

def _embed_with_facenet(face_rgb: "np.ndarray") -> list[float]:
    """
    Gera embedding 512-dim com FaceNet InceptionResnetV1 (VGGFace2).

    1. Redimensiona para 160x160 (input padrao)
    2. Normaliza pixels: [0, 255] → [-1, 1]
    3. Inferencia no modelo (sem gradientes)
    4. Retorna vetor de 512 floats
    """
    model = _get_facenet()

    resized = cv2.resize(face_rgb, (_FACE_INPUT_SIZE, _FACE_INPUT_SIZE), interpolation=cv2.INTER_CUBIC)

    # CHW tensor, normalizado para [-1, 1]
    tensor = torch.from_numpy(resized).float().permute(2, 0, 1)
    tensor = (tensor - 127.5) / 128.0
    tensor = tensor.unsqueeze(0)  # adiciona dimensao de batch

    with torch.no_grad():
        embedding = model(tensor)

    return embedding.squeeze(0).tolist()


# ─── API publica do servico ───────────────────────────────────────────────────

def _has_face_landmarks(img_rgb: "np.ndarray") -> tuple[bool, list[dict]]:
    """Deteta rostos e extrai informacao de landmarks para avaliacao de qualidade."""
    if not FACE_RECOGNITION_AVAILABLE:
        return True, [{
            "feature_count": 72,
            "has_nose_bridge": True,
            "has_eye_regions": True,
        }]

    face_locations = face_recognition.face_locations(img_rgb, model="hog")
    if not face_locations:
        return False, []

    face_landmarks_list = face_recognition.face_landmarks(img_rgb, face_locations)
    if not face_landmarks_list:
        return False, []

    landmarks_info = []
    for landmarks in face_landmarks_list:
        total_points = sum(len(pts) for pts in landmarks.values())
        landmarks_info.append({
            "feature_count": total_points,
            "has_nose_bridge": "nose_bridge" in landmarks and len(landmarks["nose_bridge"]) > 2,
            "has_eye_regions": all(k in landmarks for k in ["left_eye", "right_eye"]),
        })
    return True, landmarks_info


def assess_capture_quality(image_base64: str) -> tuple[float, "str | None"]:
    """
    Avalia qualidade da captura:
    - Detecao de face (OpenCV + Dlib)
    - Nitidez via Laplaciano
    - Iluminacao via histograma
    - Tamanho relativo do rosto
    """
    img = _base64_to_numpy(image_base64)
    if img is None:
        return 0.0, "invalid_image"

    height, width = img.shape[:2]
    if height < 100 or width < 100:
        return 0.1, "image_too_small"

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    face_detected, landmarks_info = _has_face_landmarks(img_rgb)
    if not face_detected:
        return 0.15, "no_face_detected"

    sharpness = _compute_sharpness(img)
    brightness, brightness_ok = _compute_brightness(img)
    face_size_score = _compute_face_size_score(img_rgb, landmarks_info)

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


def _compute_face_size_score(img_rgb: "np.ndarray", landmarks_info: list[dict]) -> float:
    """Score baseado no tamanho relativo do rosto (Etapa 1 — OpenCV)."""
    faces = _detect_faces_opencv(cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR))
    if not faces:
        if FACE_RECOGNITION_AVAILABLE:
            dlib_locs = face_recognition.face_locations(img_rgb, model="hog")
            if not dlib_locs:
                return 0.0 if FACE_RECOGNITION_AVAILABLE else 0.5
            faces = [(l, t, r - l, b - t) for (t, r, b, l) in dlib_locs]
        else:
            return 0.5

    height, width = img_rgb.shape[:2]
    image_area = height * width
    ideal_ratio = 0.15

    scores = [
        max(0.0, 1.0 - abs((w * h / image_area) - ideal_ratio) / ideal_ratio)
        for (_, __, w, h) in faces
    ]
    return round(max(scores), 4)


def estimate_liveness(image_base64: str, quality_score: "float | None" = None) -> float:
    """
    Estima liveness com metricas anti-spoofing:
    - Textura (variancia de gradientes)
    - Frequencia (FFT — reais vs. telas)
    - Variancia de cor (pele real vs. reproducao)
    """
    img = _base64_to_numpy(image_base64)
    if img is None:
        return 0.0

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    face_detected, _ = _has_face_landmarks(img_rgb)
    if not face_detected:
        return 0.0

    liveness = round(
        (_compute_texture_score(img) * 0.35)
        + (_compute_frequency_score(img) * 0.30)
        + (_compute_color_variance_score(img) * 0.20)
        + ((quality_score or 0.5) * 0.15),
        4,
    )
    return min(liveness, 1.0)


def _compute_texture_score(img_bgr: "np.ndarray") -> float:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    gx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
    gy = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
    return min(float(np.var(np.sqrt(gx ** 2 + gy ** 2))) / 200.0, 1.0)


def _compute_frequency_score(img_bgr: "np.ndarray") -> float:
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY).astype(np.float32)
    f_shift = np.fft.fftshift(np.fft.fft2(gray))
    magnitude = np.abs(f_shift)
    h, w = magnitude.shape
    ch, cw = h // 2, w // 2
    low = magnitude[ch - 10:ch + 10, cw - 10:cw + 10]
    high = np.concatenate([
        magnitude[:ch - 10, :].flatten(),
        magnitude[ch + 10:, :].flatten(),
        magnitude[ch - 10:ch + 10, :cw - 10].flatten(),
        magnitude[ch - 10:ch + 10, cw + 10:].flatten(),
    ])
    total = float(np.sum(low) + np.sum(high))
    return min(float(np.sum(high)) / total * 2.0, 1.0) if total > 0 else 0.5


def _compute_color_variance_score(img_bgr: "np.ndarray") -> float:
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    combined = (float(np.var(hsv[:, :, 0])) + float(np.var(hsv[:, :, 1]))) / 2.0
    return min(combined / 100.0, 1.0)


def build_embedding(image_base64: str) -> list[float]:
    """
    Pipeline completo de 3 etapas:
      1. OpenCV Haar Cascade → detetar rosto
      2. Dlib 68 landmarks   → alinhar rosto (160x160)
      3. FaceNet ResNetV1    → embedding 512-dim normalizado
    """
    if not FACENET_AVAILABLE:
        log.warning("Utilizando EMBEDDING SIMULADO (facenet-pytorch nao instalado)")
        import random
        seed = len(image_base64) % 1000
        rng = random.Random(seed)
        return _normalize_vector([rng.uniform(-1, 1) for _ in range(EMBEDDING_DIM)])

    img = _base64_to_numpy(image_base64)
    if img is None:
        raise ValueError("invalid_image")

    # Etapas 1 + 2: detecao + alinhamento
    aligned_face = _extract_aligned_face(img)
    if aligned_face is None:
        raise ValueError("no_face_detected")

    # Etapa 3: FaceNet embedding
    raw_embedding = _embed_with_facenet(aligned_face)
    return _normalize_vector(raw_embedding)


def average_embeddings(embeddings: list[list[float]]) -> list[float]:
    """Media de multiplos embeddings com normalizacao L2."""
    if not embeddings:
        raise ValueError("no_embeddings")
    dim = len(embeddings[0])
    combined = [sum(emb[i] for emb in embeddings) / len(embeddings) for i in range(dim)]
    return _normalize_vector(combined)


def serialize_embedding(embedding: list[float]) -> bytes:
    return json.dumps(embedding, separators=(",", ":")).encode("utf-8")


def deserialize_embedding(blob: bytes) -> list[float]:
    try:
        return [float(v) for v in json.loads(blob.decode("utf-8"))]
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
