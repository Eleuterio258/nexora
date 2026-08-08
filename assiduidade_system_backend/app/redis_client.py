"""Cliente Redis partilhado para proteção contra replay e cache."""

import redis

from app.config import settings

_redis_client: redis.Redis | None = None


def get_redis() -> redis.Redis:
    """Devolve o cliente Redis global, criando-o se necessário."""
    global _redis_client
    if _redis_client is None:
        _redis_client = redis.from_url(settings.redis_url, decode_responses=True)
    return _redis_client


def get_redis_client() -> redis.Redis | None:
    """Devolve o cliente Redis global ou None se ainda nao foi configurado."""
    return _redis_client


def set_redis_client(client: redis.Redis) -> None:
    """Permite injetar um cliente Redis (útil para testes com fakeredis)."""
    global _redis_client
    _redis_client = client
