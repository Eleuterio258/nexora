"""
Transformacao cancelavel para embeddings faciais.

Aplica uma transformacao irreversivel (sem o segredo) ao embedding antes de
persistir. Em caso de comprometimento do template, basta alterar o segredo/
versao da transformacao e re-gerar os embeddings transformados — os templates
originais nao precisam de ser recapturados.

A transformacao usa uma matriz ortogonal gerada deterministicamente a partir de
um seed derivado do segredo. A inversa e a transposta, o que permite comparar
embeddings no espaco transformado.

Para activar, configure CANCELABLE_TRANSFORM_SECRET e CANCELABLE_TRANSFORM_VERSION.
"""

from __future__ import annotations

import hashlib
import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import numpy as np

log = logging.getLogger(__name__)


def _derive_seed(secret: str, version: str, dim: int) -> int:
    """Deriva um seed deterministico a partir do segredo e versao."""
    raw = f"{secret}:{version}:{dim}".encode("utf-8")
    digest = hashlib.sha256(raw).digest()
    return int.from_bytes(digest[:8], "big")


class CancelableTransform:
    """Transformacao cancelavel baseada em matriz ortogonal."""

    def __init__(self, secret: str, version: str = "v1") -> None:
        if not secret:
            raise RuntimeError("CANCELABLE_TRANSFORM_SECRET nao configurado.")
        self._secret = secret
        self._version = version

    def _get_matrix(self, dim: int) -> "np.ndarray":
        """Gera uma matriz ortogonal dim x dim a partir do seed."""
        import numpy as np

        seed = _derive_seed(self._secret, self._version, dim)
        rng = np.random.default_rng(seed)
        matrix = rng.normal(size=(dim, dim))
        q, _ = np.linalg.qr(matrix)
        return q

    def transform(self, embedding: list[float]) -> list[float]:
        """Aplica a transformacao cancelavel a um embedding."""
        import numpy as np

        dim = len(embedding)
        matrix = self._get_matrix(dim)
        vector = np.array(embedding, dtype=np.float32)
        transformed = vector @ matrix
        # Normaliza para manter comparabilidade com cosine similarity.
        norm = np.linalg.norm(transformed)
        if norm > 0:
            transformed = transformed / norm
        return transformed.tolist()

    def transform_batch(self, embeddings: list[list[float]]) -> list[list[float]]:
        """Aplica a transformacao a varios embeddings."""
        return [self.transform(emb) for emb in embeddings]

    @property
    def version(self) -> str:
        return self._version
