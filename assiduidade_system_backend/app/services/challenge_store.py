"""
Armazenamento de liveness challenges com suporte a memoria local e Redis.

Em ambiente single-instance, o backend `memory` e suficiente. Em producao com
multiplas replicas, deve-se usar `redis` para partilhar o estado entre
instancias do FaceClock.
"""

from __future__ import annotations

import json
import logging
import time
from abc import ABC, abstractmethod
from dataclasses import asdict
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.services.liveness_challenge import LivenessChallenge

log = logging.getLogger(__name__)


class ChallengeStore(ABC):
    """Backend de persistencia para desafios de liveness."""

    @abstractmethod
    def set(self, challenge: "LivenessChallenge", ttl_seconds: int) -> None: ...

    @abstractmethod
    def get(self, challenge_id: str) -> "LivenessChallenge | None": ...

    @abstractmethod
    def consume(self, challenge_id: str) -> bool: ...


class MemoryChallengeStore(ChallengeStore):
    """Backend em memoria (default, single-instance)."""

    def __init__(self) -> None:
        self._challenges: dict[str, dict] = {}

    def set(self, challenge: "LivenessChallenge", ttl_seconds: int) -> None:
        from app.services.liveness_challenge import LivenessChallenge

        data = asdict(challenge)
        data["expires_at"] = time.monotonic() + ttl_seconds
        self._challenges[challenge.challenge_id] = data

    def get(self, challenge_id: str) -> "LivenessChallenge | None":
        from app.services.liveness_challenge import LivenessChallenge

        data = self._challenges.get(challenge_id)
        if data is None:
            return None
        if data.get("used") or time.monotonic() > data.get("expires_at", 0):
            return None
        return LivenessChallenge(
            challenge_id=data["challenge_id"],
            action=data["action"],
            user_id=data["user_id"],
            created_at=data["created_at"],
            used=data["used"],
        )

    def consume(self, challenge_id: str) -> bool:
        data = self._challenges.get(challenge_id)
        if data is None or data.get("used"):
            return False
        data["used"] = True
        return True


class RedisChallengeStore(ChallengeStore):
    """Backend Redis para multiplas replicas.

    Requer que `app.redis_client.get_redis_client()` devolva uma conexao valida.
    """

    def __init__(self) -> None:
        from app.redis_client import get_redis_client

        self._redis = get_redis_client()
        if self._redis is None:
            raise RuntimeError("Redis client nao configurado para LIVENESS_CHALLENGE_STORE=redis")

    def _key(self, challenge_id: str) -> str:
        return f"faceclock:liveness_challenge:{challenge_id}"

    def set(self, challenge: "LivenessChallenge", ttl_seconds: int) -> None:
        data = asdict(challenge)
        self._redis.setex(
            self._key(challenge.challenge_id),
            ttl_seconds,
            json.dumps(data),
        )

    def get(self, challenge_id: str) -> "LivenessChallenge | None":
        from app.services.liveness_challenge import LivenessChallenge

        raw = self._redis.get(self._key(challenge_id))
        if raw is None:
            return None
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return None
        return LivenessChallenge(
            challenge_id=data["challenge_id"],
            action=data["action"],
            user_id=data["user_id"],
            created_at=data["created_at"],
            used=data["used"],
        )

    def consume(self, challenge_id: str) -> bool:
        key = self._key(challenge_id)
        raw = self._redis.get(key)
        if raw is None:
            return False
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return False
        if data.get("used"):
            return False
        data["used"] = True
        ttl = self._redis.ttl(key)
        ttl = max(ttl, 1)
        self._redis.setex(key, ttl, json.dumps(data))
        return True


_store: ChallengeStore | None = None


def get_challenge_store() -> ChallengeStore:
    """Factory singleton que usa a configuracao global."""
    global _store

    if _store is not None:
        return _store

    from app.config import settings

    backend = settings.liveness_challenge_store.lower()
    if backend == "redis":
        _store = RedisChallengeStore()
    elif backend == "memory":
        _store = MemoryChallengeStore()
    else:
        raise RuntimeError(f"Backend de challenge store desconhecido: {backend}")

    log.info("Challenge store backend: %s", backend)
    return _store


def set_challenge_store(store: ChallengeStore) -> None:
    """Permite injecao de um store especifico em testes."""
    global _store
    _store = store
