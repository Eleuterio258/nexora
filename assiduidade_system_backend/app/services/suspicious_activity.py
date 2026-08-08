"""
Deteccao de tentativas suspeitas: contador de falhas consecutivas de
verify/liveness numa janela deslizante, por utilizador e por dispositivo.

Usa o mesmo backend pluggavel memory/redis do liveness challenge store
(LIVENESS_CHALLENGE_STORE) — nao ha uma env var separada, porque a decisao
operacional (single-instance vs multi-replica) e a mesma para os dois
subsistemas.
"""

from __future__ import annotations

import logging
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass

log = logging.getLogger(__name__)


@dataclass
class FlaggedEntity:
    tenant_id: str | None
    kind: str  # "user" | "device"
    identifier: str
    failure_count: int


class SuspiciousActivityStore(ABC):
    """Backend de persistencia para contadores de falhas consecutivas."""

    @abstractmethod
    def record_failure(self, tenant_id: str | None, kind: str, identifier: str) -> int:
        """Regista uma falha e devolve a contagem actual na janela."""

    @abstractmethod
    def record_success(self, tenant_id: str | None, kind: str, identifier: str) -> None:
        """Limpa o historico de falhas (sucesso reinicia a contagem)."""

    @abstractmethod
    def list_flagged(self, tenant_id: str | None) -> list[FlaggedEntity]:
        """Lista entidades com contagem >= threshold. tenant_id=None devolve todas."""


class MemorySuspiciousActivityStore(SuspiciousActivityStore):
    """Backend em memoria (default, single-instance)."""

    def __init__(self) -> None:
        from app.config import settings

        self._window_seconds = settings.suspicious_activity_window_seconds
        self._threshold = settings.suspicious_activity_threshold
        self._failures: dict[tuple[str | None, str, str], list[float]] = {}

    def _prune(self, key: tuple[str | None, str, str]) -> list[float]:
        cutoff = time.monotonic() - self._window_seconds
        timestamps = [t for t in self._failures.get(key, []) if t >= cutoff]
        if timestamps:
            self._failures[key] = timestamps
        else:
            self._failures.pop(key, None)
        return timestamps

    def record_failure(self, tenant_id: str | None, kind: str, identifier: str) -> int:
        key = (tenant_id, kind, identifier)
        timestamps = self._prune(key)
        timestamps.append(time.monotonic())
        self._failures[key] = timestamps
        return len(timestamps)

    def record_success(self, tenant_id: str | None, kind: str, identifier: str) -> None:
        self._failures.pop((tenant_id, kind, identifier), None)

    def list_flagged(self, tenant_id: str | None) -> list[FlaggedEntity]:
        flagged: list[FlaggedEntity] = []
        for key in list(self._failures.keys()):
            entry_tenant_id, kind, identifier = key
            if tenant_id is not None and entry_tenant_id != tenant_id:
                continue
            count = len(self._prune(key))
            if count >= self._threshold:
                flagged.append(FlaggedEntity(entry_tenant_id, kind, identifier, count))
        return flagged


class RedisSuspiciousActivityStore(SuspiciousActivityStore):
    """Backend Redis para multiplas replicas.

    Requer que `app.redis_client.get_redis_client()` devolva uma conexao
    valida. Usa um sorted set por chave (nao INCR) porque a janela e
    deslizante: cada falha e um membro pontuado pelo timestamp, e entradas
    fora da janela sao removidas a cada acesso.
    """

    _PREFIX = "faceclock:suspicious:"

    def __init__(self) -> None:
        from app.config import settings
        from app.redis_client import get_redis_client

        self._window_seconds = settings.suspicious_activity_window_seconds
        self._threshold = settings.suspicious_activity_threshold
        self._redis = get_redis_client()
        if self._redis is None:
            raise RuntimeError("Redis client nao configurado para deteccao de actividade suspeita")

    def _key(self, tenant_id: str | None, kind: str, identifier: str) -> str:
        return f"{self._PREFIX}{kind}:{tenant_id or '_'}:{identifier}"

    def _parse_key(self, key: str) -> tuple[str | None, str, str]:
        rest = key[len(self._PREFIX):]
        kind, tenant_part, identifier = rest.split(":", 2)
        return (None if tenant_part == "_" else tenant_part), kind, identifier

    def record_failure(self, tenant_id: str | None, kind: str, identifier: str) -> int:
        key = self._key(tenant_id, kind, identifier)
        now = time.time()
        cutoff = now - self._window_seconds
        self._redis.zadd(key, {f"{now}:{id(object())}": now})
        self._redis.zremrangebyscore(key, "-inf", cutoff)
        self._redis.expire(key, self._window_seconds)
        return int(self._redis.zcard(key))

    def record_success(self, tenant_id: str | None, kind: str, identifier: str) -> None:
        self._redis.delete(self._key(tenant_id, kind, identifier))

    def list_flagged(self, tenant_id: str | None) -> list[FlaggedEntity]:
        flagged: list[FlaggedEntity] = []
        cutoff = time.time() - self._window_seconds
        cursor = 0
        while True:
            cursor, keys = self._redis.scan(cursor=cursor, match=f"{self._PREFIX}*", count=100)
            for key in keys:
                key_str = key.decode() if isinstance(key, bytes) else key
                self._redis.zremrangebyscore(key_str, "-inf", cutoff)
                count = int(self._redis.zcard(key_str))
                if count == 0:
                    continue
                entry_tenant_id, kind, identifier = self._parse_key(key_str)
                if tenant_id is not None and entry_tenant_id != tenant_id:
                    continue
                if count >= self._threshold:
                    flagged.append(FlaggedEntity(entry_tenant_id, kind, identifier, count))
            if cursor == 0:
                break
        return flagged


_store: SuspiciousActivityStore | None = None


def get_suspicious_activity_store() -> SuspiciousActivityStore:
    """Factory singleton que usa a mesma configuracao do challenge store."""
    global _store

    if _store is not None:
        return _store

    from app.config import settings

    backend = settings.liveness_challenge_store.lower()
    if backend == "redis":
        _store = RedisSuspiciousActivityStore()
    elif backend == "memory":
        _store = MemorySuspiciousActivityStore()
    else:
        raise RuntimeError(f"Backend de suspicious activity store desconhecido: {backend}")

    log.info("Suspicious activity store backend: %s", backend)
    return _store


def set_suspicious_activity_store(store: SuspiciousActivityStore) -> None:
    """Permite injecao de um store especifico em testes."""
    global _store
    _store = store


def record_verify_failure(
    tenant_id: str | None,
    erp_user_id: str | None,
    device_id: str | None,
    reason: str,
) -> None:
    """Regista uma falha de verify/liveness para o utilizador e o dispositivo,
    alertando (log.warning) se o threshold for cruzado."""
    from app.config import settings

    store = get_suspicious_activity_store()
    if erp_user_id:
        count = store.record_failure(tenant_id, "user", erp_user_id)
        if count >= settings.suspicious_activity_threshold:
            log.warning(
                "Actividade suspeita: %d falhas consecutivas (tenant=%s, user=%s, motivo=%s, janela=%ds)",
                count, tenant_id, erp_user_id, reason, settings.suspicious_activity_window_seconds,
            )
    if device_id:
        count = store.record_failure(tenant_id, "device", device_id)
        if count >= settings.suspicious_activity_threshold:
            log.warning(
                "Actividade suspeita: %d falhas consecutivas (tenant=%s, device=%s, motivo=%s, janela=%ds)",
                count, tenant_id, device_id, reason, settings.suspicious_activity_window_seconds,
            )


def record_verify_success(
    tenant_id: str | None,
    erp_user_id: str | None,
    device_id: str | None,
) -> None:
    """Limpa os contadores de falha apos uma verificacao bem sucedida."""
    store = get_suspicious_activity_store()
    if erp_user_id:
        store.record_success(tenant_id, "user", erp_user_id)
    if device_id:
        store.record_success(tenant_id, "device", device_id)
