import time

import pytest

from app.services.challenge_store import (
    MemoryChallengeStore,
    RedisChallengeStore,
    get_challenge_store,
    set_challenge_store,
)
from app.services.liveness_challenge import ChallengeAction, LivenessChallenge


@pytest.fixture
def sample_challenge():
    return LivenessChallenge(
        challenge_id="ch-1",
        action=ChallengeAction.BLINK,
        user_id="user-1",
        created_at=time.monotonic(),
        used=False,
    )


def test_memory_challenge_store_lifecycle(sample_challenge):
    store = MemoryChallengeStore()
    store.set(sample_challenge, ttl_seconds=60)

    retrieved = store.get(sample_challenge.challenge_id)
    assert retrieved is not None
    assert retrieved.user_id == "user-1"
    assert retrieved.action == ChallengeAction.BLINK
    assert retrieved.used is False

    assert store.consume(sample_challenge.challenge_id) is True
    assert store.get(sample_challenge.challenge_id) is None
    assert store.consume(sample_challenge.challenge_id) is False


def test_memory_challenge_store_expiration(sample_challenge):
    store = MemoryChallengeStore()
    store.set(sample_challenge, ttl_seconds=0)
    time.sleep(0.01)
    assert store.get(sample_challenge.challenge_id) is None


def test_get_challenge_store_default():
    store = get_challenge_store()
    assert isinstance(store, MemoryChallengeStore)


def test_set_challenge_store_injection(sample_challenge):
    original = get_challenge_store()
    custom = MemoryChallengeStore()
    set_challenge_store(custom)

    try:
        custom.set(sample_challenge, ttl_seconds=60)
        assert get_challenge_store().get(sample_challenge.challenge_id) is not None
    finally:
        set_challenge_store(original)


def test_redis_challenge_store_requires_client():
    # Sem Redis configurado, a criacao deve falhar de forma controlada.
    with pytest.raises(RuntimeError):
        RedisChallengeStore()
