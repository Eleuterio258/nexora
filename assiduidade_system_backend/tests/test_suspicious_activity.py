import fakeredis
import pytest

from app.redis_client import set_redis_client
from app.services.suspicious_activity import (
    MemorySuspiciousActivityStore,
    RedisSuspiciousActivityStore,
    get_suspicious_activity_store,
    set_suspicious_activity_store,
)


@pytest.fixture(autouse=True)
def _reset_store():
    yield
    set_suspicious_activity_store(None)


class TestMemorySuspiciousActivityStore:
    def test_record_failure_increments_count(self):
        store = MemorySuspiciousActivityStore()
        assert store.record_failure("tenant-1", "user", "u1") == 1
        assert store.record_failure("tenant-1", "user", "u1") == 2
        assert store.record_failure("tenant-1", "user", "u1") == 3

    def test_record_success_resets_count(self):
        store = MemorySuspiciousActivityStore()
        store.record_failure("tenant-1", "user", "u1")
        store.record_failure("tenant-1", "user", "u1")
        store.record_success("tenant-1", "user", "u1")
        assert store.record_failure("tenant-1", "user", "u1") == 1

    def test_list_flagged_only_above_threshold(self):
        store = MemorySuspiciousActivityStore()
        for _ in range(store._threshold - 1):
            store.record_failure("tenant-1", "user", "below")
        for _ in range(store._threshold):
            store.record_failure("tenant-1", "user", "above")

        flagged = store.list_flagged(None)
        identifiers = {f.identifier for f in flagged}
        assert "above" in identifiers
        assert "below" not in identifiers

    def test_list_flagged_filters_by_tenant(self):
        store = MemorySuspiciousActivityStore()
        for _ in range(store._threshold):
            store.record_failure("tenant-1", "user", "u1")
            store.record_failure("tenant-2", "user", "u2")

        flagged_tenant_1 = store.list_flagged("tenant-1")
        identifiers = {f.identifier for f in flagged_tenant_1}
        assert identifiers == {"u1"}

    def test_user_and_device_tracked_independently(self):
        store = MemorySuspiciousActivityStore()
        store.record_failure("tenant-1", "user", "u1")
        store.record_failure("tenant-1", "device", "d1")
        store.record_failure("tenant-1", "device", "d1")
        assert store.record_failure("tenant-1", "user", "u1") == 2
        assert store.record_failure("tenant-1", "device", "d1") == 3


class TestRedisSuspiciousActivityStore:
    @pytest.fixture(autouse=True)
    def _fake_redis(self):
        client = fakeredis.FakeStrictRedis(version=6)
        set_redis_client(client)
        yield client
        set_redis_client(None)

    def test_record_failure_increments_count(self):
        store = RedisSuspiciousActivityStore()
        assert store.record_failure("tenant-1", "user", "u1") == 1
        assert store.record_failure("tenant-1", "user", "u1") == 2

    def test_record_success_resets_count(self):
        store = RedisSuspiciousActivityStore()
        store.record_failure("tenant-1", "user", "u1")
        store.record_success("tenant-1", "user", "u1")
        assert store.record_failure("tenant-1", "user", "u1") == 1

    def test_list_flagged_only_above_threshold(self):
        store = RedisSuspiciousActivityStore()
        for _ in range(store._threshold):
            store.record_failure("tenant-1", "user", "above")
        store.record_failure("tenant-1", "user", "below")

        flagged = store.list_flagged(None)
        identifiers = {f.identifier for f in flagged}
        assert "above" in identifiers
        assert "below" not in identifiers


class TestFactory:
    def test_get_suspicious_activity_store_memory_default(self, monkeypatch):
        monkeypatch.setattr("app.config.settings.liveness_challenge_store", "memory")
        store = get_suspicious_activity_store()
        assert isinstance(store, MemorySuspiciousActivityStore)

    def test_set_suspicious_activity_store_injects_instance(self):
        custom = MemorySuspiciousActivityStore()
        set_suspicious_activity_store(custom)
        assert get_suspicious_activity_store() is custom
