"""
Detectores de face plugaveis.

Suporta:
- blaze_face: MediaPipe BlazeFace (default, ja existente)
- yunet: OpenCV YuNet (mais robusto a pose/oclusao)

A selecao e feita pela env var BIOMETRIC_FACE_DETECTOR.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from pathlib import Path
from typing import TYPE_CHECKING, ClassVar

if TYPE_CHECKING:
    import numpy as np

log = logging.getLogger(__name__)


class FaceDetectionResult:
    """Resultado normalizado de deteccao de face."""

    def __init__(
        self,
        bbox: tuple[float, float, float, float],
        keypoints: list[tuple[float, float]],
        confidence: float,
    ) -> None:
        self.bbox = bbox  # (x, y, width, height)
        self.keypoints = keypoints  # [(x0, y0), ...]
        self.confidence = confidence


class FaceDetector(ABC):
    """Interface para detectores de face."""

    @abstractmethod
    def detect(self, img_bgr: "np.ndarray") -> list[FaceDetectionResult]: ...


class BlazeFaceDetector(FaceDetector):
    """Detector MediaPipe BlazeFace (short-range)."""

    def __init__(self) -> None:
        from app.services import biometric

        if not biometric.MEDIAPIPE_AVAILABLE:
            raise RuntimeError("MediaPipe face detector nao disponivel.")

    def detect(self, img_bgr: "np.ndarray") -> list[FaceDetectionResult]:
        import cv2
        import mediapipe as mp

        from app.services.biometric import _get_face_detector

        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)
        result = _get_face_detector().detect(mp_image)

        detections: list[FaceDetectionResult] = []
        # O DetectionResult das MediaPipe Tasks expõe `detections`; não existe
        # `face_detections` (esse é o nome da solução legada mp.solutions).
        if result.detections:
            height, width = img_bgr.shape[:2]
            for detection in result.detections:
                bbox = detection.bounding_box
                x = bbox.origin_x / width
                y = bbox.origin_y / height
                w = bbox.width / width
                h = bbox.height / height
                keypoints = [
                    (kp.x, kp.y)
                    for kp in detection.keypoints
                ]
                detections.append(
                    FaceDetectionResult(
                        bbox=(x, y, w, h),
                        keypoints=keypoints,
                        confidence=detection.categories[0].score if detection.categories else 0.0,
                    )
                )
        return detections


class YuNetDetector(FaceDetector):
    """Detector OpenCV YuNet.

    Requer o modelo ONNX em app/ml_models/face_detection_yunet.onnx.
    """

    _MODEL_PATH: ClassVar[Path] = (
        Path(__file__).resolve().parent.parent / "ml_models" / "face_detection_yunet.onnx"
    )

    def __init__(self, input_size: tuple[int, int] = (320, 320), score_threshold: float = 0.6) -> None:
        import cv2

        if not self._MODEL_PATH.is_file():
            raise RuntimeError(
                f"Modelo YuNet nao encontrado em {self._MODEL_PATH}. "
                "Execute: ./venv/Scripts/python scripts/download_yunet_model.py"
            )

        self._detector = cv2.FaceDetectorYN_create(
            model=str(self._MODEL_PATH),
            config="",
            input_size=input_size,
            score_threshold=score_threshold,
            nms_threshold=0.3,
            top_k=5000,
        )

    def detect(self, img_bgr: "np.ndarray") -> list[FaceDetectionResult]:
        import numpy as np

        height, width = img_bgr.shape[:2]
        self._detector.setInputSize((width, height))
        _, faces = self._detector.detect(img_bgr)

        detections: list[FaceDetectionResult] = []
        if faces is None:
            return detections

        for face in faces:
            # YuNet devolve: [x, y, w, h, rx, ry, lx, ly, nx, ny, rcmx, rcmy, score]
            x, y, w, h = face[:4]
            score = float(face[-1])
            keypoints = [
                (float(face[4]) / width, float(face[5]) / height),   # right eye
                (float(face[6]) / width, float(face[7]) / height),   # left eye
                (float(face[8]) / width, float(face[9]) / height),   # nose tip
                (float(face[10]) / width, float(face[11]) / height), # right mouth corner
                (float(face[12]) / width, float(face[13]) / height), # left mouth corner
            ]
            detections.append(
                FaceDetectionResult(
                    bbox=(x / width, y / height, w / width, h / height),
                    keypoints=keypoints,
                    confidence=score,
                )
            )
        return detections


_REGISTRY: dict[str, type[FaceDetector]] = {
    "blaze_face": BlazeFaceDetector,
    "yunet": YuNetDetector,
}

_detector_cache: dict[str, FaceDetector] = {}


def list_face_detectors() -> list[str]:
    return list(_REGISTRY.keys())


def get_face_detector(name: str | None = None) -> FaceDetector:
    from app.config import settings

    detector_name = (name or settings.biometric_face_detector).lower()
    if detector_name not in _REGISTRY:
        raise RuntimeError(
            f"Detector de face desconhecido: {detector_name}. Opcoes: {list(_REGISTRY.keys())}"
        )
    if detector_name not in _detector_cache:
        _detector_cache[detector_name] = _REGISTRY[detector_name]()
    return _detector_cache[detector_name]


def reset_face_detector_cache() -> None:
    """Limpa a cache de detectores. Util em testes que trocam de detector."""
    _detector_cache.clear()
