import uuid

import jwt
import pytest

from app.config import settings
from app.services.challenge_store import MemoryChallengeStore, set_challenge_store
from tests.test_api import _sign, fake_redis, system_credential  # noqa: F401 (fixtures)

_SAME_PERSON = [0.5] * 512
# Ortogonal a _SAME_PERSON (cosseno 0): outra pessoa.
_OTHER_PERSON = [0.5 if i % 2 == 0 else -0.5 for i in range(512)]


@pytest.fixture(autouse=True)
def memory_challenge_store():
    set_challenge_store(MemoryChallengeStore())
    yield
    set_challenge_store(None)


@pytest.fixture
def enrolled_user(client, fake_redis, system_credential, monkeypatch):  # noqa: F811
    from app import erp_client as erp_client_module
    from app.routers import biometric as biometric_router

    monkeypatch.setattr(biometric_router, "assess_capture_quality", lambda *a, **k: (0.95, None))
    monkeypatch.setattr(biometric_router, "build_embedding", lambda *a, **k: _SAME_PERSON)
    monkeypatch.setattr(biometric_router, "estimate_liveness", lambda *a, **k: 0.95)

    async def _fake_consentimento(*args, **kwargs):
        return {"id": "fake"}

    monkeypatch.setattr(erp_client_module.erp_client, "validar_consentimento_ativo", _fake_consentimento)

    cred, secret = system_credential
    user_id = str(uuid.uuid4())
    payload = {"user_id": user_id, "captures": [{"image_base64": "fake", "angle": "front"} for _ in range(3)]}
    headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/biometric/enroll", payload=payload)
    assert client.post("/api/v1/biometric/enroll", content=body, headers=headers).status_code == 201
    return user_id


def _mock_liveness_pipeline(monkeypatch, frame_embeddings: dict[str, list[float]]):
    from app.routers import liveness as liveness_router
    from app.services import liveness_challenge

    monkeypatch.setattr(liveness_router, "verify_challenge_sequence", lambda *a, **k: (True, {}))
    # O frame "best" tem a melhor qualidade -> e o usado no match.
    monkeypatch.setattr(
        liveness_router,
        "assess_capture_quality",
        lambda frame, *a, **k: (0.99 if frame == "best" else 0.80, None),
    )
    monkeypatch.setattr(liveness_router, "build_embedding", lambda frame, *a, **k: frame_embeddings[frame])
    monkeypatch.setattr(liveness_router, "estimate_liveness", lambda *a, **k: 0.95)
    monkeypatch.setattr(liveness_challenge, "build_embedding", lambda frame, *a, **k: frame_embeddings[frame])


def _run_challenge(client, cred, secret, user_id, frames):
    payload = {"user_id": user_id}
    headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/liveness/challenge", payload=payload)
    response = client.post("/api/v1/liveness/challenge", content=body, headers=headers)
    assert response.status_code == 201
    challenge_id = response.json()["challenge_id"]

    device_id = str(uuid.uuid4())
    payload = {"challenge_id": challenge_id, "user_id": user_id, "device_id": device_id, "frames_base64": frames}
    headers, body = _sign(secret, cred.access_key_id, "POST", "/api/v1/liveness/verify", payload=payload)
    response = client.post("/api/v1/liveness/verify", content=body, headers=headers)
    assert response.status_code == 200
    return response.json(), device_id


def test_liveness_verify_issues_active_challenge_token(
    client, system_credential, enrolled_user, monkeypatch  # noqa: F811
):
    frames = ["best", "f1", "f2", "f3"]
    _mock_liveness_pipeline(monkeypatch, {f: _SAME_PERSON for f in frames})
    cred, secret = system_credential

    data, device_id = _run_challenge(client, cred, secret, enrolled_user, frames)

    assert data["match"] is True
    claims = jwt.decode(
        data["verification_token"],
        settings.facial_verification_secret,
        algorithms=["HS256"],
        audience="nexora-facial-attendance",
    )
    assert claims["sub"] == enrolled_user
    assert claims["device_id"] == device_id
    assert claims["liveness_method"] == "active_challenge"


def test_liveness_verify_rejects_action_by_other_person(
    client, system_credential, enrolled_user, monkeypatch  # noqa: F811
):
    # A foto nitida da vitima ("best") da match; os frames da accao sao de outra pessoa.
    frames = ["best", "f1", "f2", "f3"]
    embeddings = {"best": _SAME_PERSON, "f1": _OTHER_PERSON, "f2": _OTHER_PERSON, "f3": _OTHER_PERSON}
    _mock_liveness_pipeline(monkeypatch, embeddings)
    cred, secret = system_credential

    data, _ = _run_challenge(client, cred, secret, enrolled_user, frames)

    assert data["match"] is False
    assert data["reason"] == "identity_discontinuity"
    assert data.get("verification_token") is None


def test_liveness_verify_rejects_single_intercalated_frame(
    client, system_credential, enrolled_user, monkeypatch  # noqa: F811
):
    frames = ["best", "f1", "f2", "f3", "f4"]
    embeddings = {f: _SAME_PERSON for f in frames}
    embeddings["f3"] = _OTHER_PERSON
    _mock_liveness_pipeline(monkeypatch, embeddings)
    cred, secret = system_credential

    data, _ = _run_challenge(client, cred, secret, enrolled_user, frames)

    assert data["reason"] == "identity_discontinuity"
