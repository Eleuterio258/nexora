"""
Modelos de Presentation Attack Detection (PAD) / liveness passiva.

A heuristica actual (textura/frequencia/cor) e mantida como default.
Quando um modelo PAD treinado for integrado (ex.: Silent-Face-Anti-Spoofing),
basta registar a classe correspondente em _LIVENESS_REGISTRY e definir
LIVENESS_MODEL=anti_spoofing.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import numpy as np

log = logging.getLogger(__name__)


class LivenessModel(ABC):
    """Interface para modelos de liveness passiva."""

    @abstractmethod
    def score(self, img_bgr: "np.ndarray") -> float:
        """Devolve score de liveness entre 0.0 (ataque) e 1.0 (vivo)."""


class HeuristicLivenessModel(LivenessModel):
    """Heuristica de imagem unica usada ate agora (textura/FFT/cor)."""

    def score(self, img_bgr: "np.ndarray") -> float:
        texture = self._texture_score(img_bgr)
        frequency = self._frequency_score(img_bgr)
        color = self._color_variance_score(img_bgr)
        return round((texture * 0.35) + (frequency * 0.30) + (color * 0.20), 4)

    @staticmethod
    def _texture_score(img_bgr: "np.ndarray") -> float:
        import cv2
        import numpy as np

        gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
        gx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        gy = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        return min(float(np.var(np.sqrt(gx ** 2 + gy ** 2))) / 200.0, 1.0)

    @staticmethod
    def _frequency_score(img_bgr: "np.ndarray") -> float:
        import cv2
        import numpy as np

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

    @staticmethod
    def _color_variance_score(img_bgr: "np.ndarray") -> float:
        import cv2
        import numpy as np

        hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
        combined = (float(np.var(hsv[:, :, 0])) + float(np.var(hsv[:, :, 1]))) / 2.0
        return min(combined / 100.0, 1.0)


class AntiSpoofingONNXModel(LivenessModel):
    """Modelo PAD baseado num classificador ONNX (ex.: Silent-Face-Anti-Spoofing
    MiniFASNet, https://github.com/minivision-ai/Silent-Face-Anti-Spoofing).

    Espera um modelo ONNX em `app/ml_models/anti_spoofing.onnx` com input
    `NCHW` ou `NHWC`. O tamanho do input e lido do proprio modelo (fallback
    128x128 se a dimensao for dinamica/desconhecida) — nao assumir um tamanho
    fixo, os modelos MiniFASNet oficiais sao 80x80, nao 128x128.

    Suporta output de 1 ou 2 classes (binario) ou 3 classes — o esquema de 3
    classes e o usado pelos checkpoints oficiais MiniFASNet (0=print attack,
    1=real, 2=replay attack; confirmado em test.py do repo oficial:
    `label = np.argmax(prediction); if label == 1: "Real Face"`). Um modelo
    de 3 classes com convencao de labels diferente da oficial precisaria de
    ajuste aqui — nao ha forma generica de adivinhar a ordem das classes.

    Se o modelo nao existir ou `onnxruntime` nao estiver instalado, levanta
    RuntimeError no carregamento, permitindo activacao futura sem alterar codigo.
    """

    _MODEL_PATH = Path(__file__).resolve().parent.parent / "ml_models" / "anti_spoofing.onnx"
    _DEFAULT_INPUT_SIZE = (128, 128)
    _REAL_FACE_CLASS_INDEX = 1  # so relevante para output de 3 classes (MiniFASNet)

    def __init__(self) -> None:
        try:
            import onnxruntime as ort
        except ImportError as exc:
            raise RuntimeError(
                "onnxruntime nao instalado. Instale com: pip install onnxruntime"
            ) from exc

        if not self._MODEL_PATH.is_file():
            raise RuntimeError(
                f"Modelo anti-spoofing nao encontrado em {self._MODEL_PATH}. "
                "Descarregue um modelo ONNX compativel ou use LIVENESS_MODEL=heuristic."
            )

        self._session = ort.InferenceSession(str(self._MODEL_PATH))
        self._input_name = self._session.get_inputs()[0].name
        input_shape = self._session.get_inputs()[0].shape
        self._input_channels_first = len(input_shape) == 4 and input_shape[1] in (1, 3)
        self._input_size = self._resolve_input_size(input_shape, self._input_channels_first)

    def _resolve_input_size(self, input_shape: list, channels_first: bool) -> tuple[int, int]:
        """Le altura/largura do input declarado pelo proprio modelo ONNX.
        Cai para o default se a dimensao for simbolica (ex.: 'batch_size',
        None) em vez de um inteiro concreto."""
        if len(input_shape) != 4:
            return self._DEFAULT_INPUT_SIZE
        h, w = (input_shape[2], input_shape[3]) if channels_first else (input_shape[1], input_shape[2])
        if isinstance(h, int) and isinstance(w, int):
            return (w, h)  # cv2.resize espera (width, height)
        return self._DEFAULT_INPUT_SIZE

    def score(self, img_bgr: "np.ndarray") -> float:
        import cv2
        import numpy as np

        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        resized = cv2.resize(img_rgb, self._input_size, interpolation=cv2.INTER_AREA)
        normalized = resized.astype(np.float32) / 255.0

        if self._input_channels_first:
            # NCHW
            normalized = np.transpose(normalized, (2, 0, 1))

        input_tensor = np.expand_dims(normalized, axis=0)
        outputs = self._session.run(None, {self._input_name: input_tensor})

        raw = np.asarray(outputs[0]).flatten()
        exp = np.exp(raw - np.max(raw))
        probs = exp / np.sum(exp)

        if probs.size == 1:
            prob_live = float(raw[0])  # ja e uma probabilidade (sigmoid), nao logit
        elif probs.size == 2:
            prob_live = float(probs[1])  # [attack, live]
        elif probs.size == 3:
            prob_live = float(probs[self._REAL_FACE_CLASS_INDEX])  # MiniFASNet: indice 1 = real
        else:
            prob_live = float(probs[-1])

        return round(max(0.0, min(1.0, prob_live)), 4)


class SilentFaceAntiSpoofingModel(AntiSpoofingONNXModel):
    """Alias para AntiSpoofingONNXModel (compatibilidade com documentacao)."""


_LIVENESS_REGISTRY: dict[str, type[LivenessModel]] = {
    "heuristic": HeuristicLivenessModel,
    "anti_spoofing": AntiSpoofingONNXModel,
    "silent_face_anti_spoofing": AntiSpoofingONNXModel,
}

_model_cache: dict[str, LivenessModel] = {}


def get_liveness_model(model_name: str | None = None) -> LivenessModel:
    from app.config import settings

    name = (model_name or settings.liveness_model).lower()
    if name not in _LIVENESS_REGISTRY:
        raise RuntimeError(f"Modelo de liveness desconhecido: {name}. Opcoes: {list(_LIVENESS_REGISTRY.keys())}")
    if name not in _model_cache:
        _model_cache[name] = _LIVENESS_REGISTRY[name]()
    return _model_cache[name]


def reset_liveness_model_cache() -> None:
    """Limpa a cache de modelos de liveness. Util em testes."""
    _model_cache.clear()


def list_liveness_models() -> list[str]:
    return list(_LIVENESS_REGISTRY.keys())
