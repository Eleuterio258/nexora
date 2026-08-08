"""
Modelos de embedding facial suportados pelo FaceClock.

A interface FaceEmbeddingModel permite trocar FaceNet por ArcFace/AdaFace/
MobileFaceNet sem alterar a logica de negocio. Cada modelo e responsavel por:
- Carregar os seus pesos
- Pre-processar a imagem de entrada
- Gerar o embedding normalizado
- Reportar a sua versao e dimensao

O modelo activo e escolhido pela env var BIOMETRIC_MODEL (default: facenet).
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import numpy as np

log = logging.getLogger(__name__)


class FaceEmbeddingModel(ABC):
    """Interface para modelos de embedding facial."""

    @property
    @abstractmethod
    def model_version(self) -> str:
        """Identificador unico do modelo (guardado nos templates)."""

    @property
    @abstractmethod
    def embedding_dim(self) -> int:
        """Dimensao do vetor de embedding."""

    @abstractmethod
    def warmup(self) -> None:
        """Carrega pesos/memorias no arranque."""

    @abstractmethod
    def embed(self, face_rgb: "np.ndarray") -> list[float]:
        """Gera embedding a partir de uma imagem RGB (H, W, 3)."""

    @abstractmethod
    def input_size(self) -> int:
        """Tamanho esperado do crop de entrada (quadrado)."""


def normalize_embedding(embedding: list[float]) -> list[float]:
    """Normaliza um embedding para norma L2 = 1."""
    import math

    norm = math.sqrt(sum(x * x for x in embedding))
    if norm == 0:
        return embedding
    return [x / norm for x in embedding]


class FaceNetEmbeddingModel(FaceEmbeddingModel):
    """FaceNet InceptionResnetV1 pre-treinado em VGGFace2 (implementacao anterior)."""

    _model = None

    @property
    def model_version(self) -> str:
        return "facenet-vggface2-v1"

    @property
    def embedding_dim(self) -> int:
        return 512

    def input_size(self) -> int:
        return 160

    def _load(self):
        if self._model is not None:
            return self._model
        try:
            import torch
            from facenet_pytorch import InceptionResnetV1
        except ImportError as exc:
            raise RuntimeError("facenet-pytorch nao instalado") from exc

        try:
            self._model = InceptionResnetV1(pretrained="vggface2").eval()
        except (OSError, RuntimeError) as exc:
            log.exception("Falha ao carregar pesos FaceNet VGGFace2")
            raise RuntimeError("facenet_model_unavailable") from exc
        log.info("FaceNet InceptionResnetV1 (VGGFace2) carregado.")
        return self._model

    def warmup(self) -> None:
        self._load()

    def embed(self, face_rgb: "np.ndarray") -> list[float]:
        import cv2
        import numpy as np
        import torch

        model = self._load()
        resized = cv2.resize(face_rgb, (self.input_size(), self.input_size()), interpolation=cv2.INTER_CUBIC)
        tensor = torch.from_numpy(resized).float().permute(2, 0, 1)
        tensor = (tensor - 127.5) / 128.0
        tensor = tensor.unsqueeze(0)

        with torch.no_grad():
            embedding = model(tensor)

        return normalize_embedding(embedding.squeeze(0).tolist())


class ArcFaceEmbeddingModel(FaceEmbeddingModel):
    """ArcFace/AdaFace via InsightFace (placeholder para activacao futura).

    Este modelo requer a instalacao de `insightface` e `onnxruntime`.
    Enquanto nao estiverem disponiveis, levanta RuntimeError ao carregar.
    """

    _model = None

    @property
    def model_version(self) -> str:
        return "arcface-insightface-v1"

    @property
    def embedding_dim(self) -> int:
        return 512

    def input_size(self) -> int:
        return 112

    def _load(self):
        if self._model is not None:
            return self._model
        try:
            import insightface
            from insightface.app import FaceAnalysis
        except ImportError as exc:
            raise RuntimeError(
                "insightface nao instalado. Instale com: "
                "pip install insightface onnxruntime"
            ) from exc

        app = FaceAnalysis(name="buffalo_l", root="/tmp/insightface")
        app.prepare(ctx_id=-1, det_size=(640, 640))
        self._model = app
        log.info("ArcFace InsightFace (buffalo_l) carregado.")
        return self._model

    def warmup(self) -> None:
        self._load()

    def embed(self, face_rgb: "np.ndarray") -> list[float]:
        import numpy as np

        model = self._load()
        faces = model.get(np.array(face_rgb))
        if not faces:
            raise ValueError("nenhuma_face_detectada_pelo_arcface")
        if len(faces) > 1:
            raise ValueError("multiplas_faces_detectadas_pelo_arcface")
        return normalize_embedding(faces[0].embedding.tolist())


_MODEL_REGISTRY: dict[str, type[FaceEmbeddingModel]] = {
    "facenet": FaceNetEmbeddingModel,
    "arcface": ArcFaceEmbeddingModel,
}


def get_embedding_model(model_name: str | None = None) -> FaceEmbeddingModel:
    """Factory que devolve a instancia do modelo configurado."""
    from app.config import settings

    name = (model_name or settings.biometric_model).lower()
    if name not in _MODEL_REGISTRY:
        raise RuntimeError(f"Modelo biometrico desconhecido: {name}. Opcoes: {list(_MODEL_REGISTRY.keys())}")
    return _MODEL_REGISTRY[name]()


def list_embedding_models() -> list[str]:
    return list(_MODEL_REGISTRY.keys())


def get_model_version(model_name: str | None = None) -> str:
    """Devolve a versao do modelo activo ou do modelo especificado."""
    return get_embedding_model(model_name).model_version


def get_embedding_dim(model_name: str | None = None) -> int:
    """Devolve a dimensao do embedding do modelo activo ou especificado."""
    return get_embedding_model(model_name).embedding_dim
