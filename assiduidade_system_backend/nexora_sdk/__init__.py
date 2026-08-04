"""SDK Python oficial Nexora para autenticação HMAC entre sistemas."""

from .client import NexoraClient
from .exceptions import (
    NexoraAuthError,
    NexoraConfigError,
    NexoraError,
    NexoraRequestError,
)

__all__ = [
    "NexoraClient",
    "NexoraError",
    "NexoraConfigError",
    "NexoraAuthError",
    "NexoraRequestError",
]

__version__ = "1.0.0"
