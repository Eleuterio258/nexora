import os

import pytest

from app.security.key_management import EnvironmentKeyProvider, get_key_provider


def test_environment_provider_reads_key(monkeypatch):
    monkeypatch.setenv("BIOMETRIC_ENCRYPTION_KEY", "a" * 32)
    provider = EnvironmentKeyProvider()
    assert provider.get_key() == b"a" * 32


def test_environment_provider_missing_key():
    provider = EnvironmentKeyProvider(env_var="MISSING_KEY_VAR_XYZ")
    with pytest.raises(RuntimeError):
        provider.get_key()


def test_get_key_provider_default():
    provider = get_key_provider()
    assert isinstance(provider, EnvironmentKeyProvider)


def test_get_key_provider_rejects_cloud_provider(monkeypatch):
    monkeypatch.setenv("BIOMETRIC_KEY_PROVIDER", "aws_kms")
    with pytest.raises(RuntimeError) as exc_info:
        get_key_provider("aws_kms")
    assert "nao suportado em modo self-hosted" in str(exc_info.value)
