"""
Matching de impressoes digitais baseado em caracteristicas locais (ORB).

Esta implementacao e self-hosted (apenas OpenCV) e nao depende de servicos
cloud nem de SDKs de fabricantes. E uma alternativa razoavel a matching de
minucias ISO quando nao ha leitor especializado disponivel.

Nota: para producao biometrica rigorosa, recomenda-se usar um leitor com SDK
proprio (ex.: DigitalPersona, ZKTeco) e fazer matching no proprio leitor ou
com bibliotecas como SourceAFIS.
"""

from __future__ import annotations

import base64
import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import numpy as np

log = logging.getLogger(__name__)

# Score minimo para considerar duas impressoes digitais como match.
_DEFAULT_MATCH_THRESHOLD = 0.25
# Numero maximo de keypoints ORB a extrair.
_MAX_FEATURES = 500


def _decode_template_image(template_base64: str) -> "np.ndarray | None":
    """Decodifica um template base64 (imagem PNG/JPEG) para array OpenCV."""
    import cv2
    import numpy as np

    try:
        raw = base64.b64decode(template_base64, validate=True)
    except Exception:
        return None

    nparr = np.frombuffer(raw, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)
    return img


def _preprocess(img: "np.ndarray") -> "np.ndarray":
    """Pre-processamento para melhorar extracao de caracteristicas."""
    import cv2

    # Equalizacao adaptativa para melhorar contraste local.
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(img)

    # Binarizacao adaptativa para destacar ridges.
    binary = cv2.adaptiveThreshold(
        enhanced, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
    )
    return binary


def _extract_features(img: "np.ndarray") -> "tuple[list, np.ndarray] | None":
    """Extrai keypoints e descritores ORB da imagem pre-processada."""
    import cv2

    if img is None or img.size == 0:
        return None

    processed = _preprocess(img)
    orb = cv2.ORB_create(nfeatures=_MAX_FEATURES)
    keypoints, descriptors = orb.detectAndCompute(processed, None)

    if descriptors is None or len(keypoints) < 8:
        return None
    return keypoints, descriptors


def match_fingerprints(
    probe_base64: str,
    reference_base64: str,
    threshold: float = _DEFAULT_MATCH_THRESHOLD,
) -> tuple[bool, float]:
    """Compara duas imagens de impressao digital.

    Retorna (is_match, score), onde score esta entre 0.0 e 1.0.
    """
    import cv2

    probe_img = _decode_template_image(probe_base64)
    ref_img = _decode_template_image(reference_base64)

    if probe_img is None or ref_img is None:
        return False, 0.0

    probe_features = _extract_features(probe_img)
    ref_features = _extract_features(ref_img)

    if probe_features is None or ref_features is None:
        return False, 0.0

    _, probe_desc = probe_features
    _, ref_desc = ref_features

    # FLANN nao e compativel com ORB; usamos forca bruta com Hamming.
    matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False)
    knn_matches = matcher.knnMatch(probe_desc, ref_desc, k=2)

    # Ratio test de Lowe para filtrar matches ruins.
    good_matches = []
    for match_pair in knn_matches:
        if len(match_pair) < 2:
            continue
        m, n = match_pair
        if m.distance < 0.75 * n.distance:
            good_matches.append(m)

    # Normaliza pelo numero minimo de keypoints para obter score 0-1.
    min_features = min(len(probe_desc), len(ref_desc))
    if min_features == 0:
        return False, 0.0

    score = len(good_matches) / min_features
    is_match = score >= threshold
    return is_match, round(score, 4)


def best_fingerprint_match(
    probe_base64: str,
    references: list[tuple[str, str]],
    threshold: float = _DEFAULT_MATCH_THRESHOLD,
) -> tuple[str | None, float]:
    """Procura o melhor match numa lista de templates.

    Args:
        probe_base64: imagem base64 da impressao digital de probe.
        references: lista de (user_id, template_base64).
        threshold: score minimo para considerar match.

    Returns:
        (user_id, score) do melhor match, ou (None, 0.0) se nenhum.
    """
    best_user: str | None = None
    best_score = 0.0

    for user_id, ref_base64 in references:
        is_match, score = match_fingerprints(probe_base64, ref_base64, threshold)
        if is_match and score > best_score:
            best_user = user_id
            best_score = score

    return best_user, round(best_score, 4)
