"""Testes da verificação local (JWKS) de access tokens RS256 do Nexora ERP —
substitui o antigo round-trip a GET /api/auth/gateway/validate. Não faz
nenhuma chamada de rede: monkeypatcha app.oauth_jwks._jwks_client() para
devolver uma chave gerada localmente, tal como o ERP publicaria em
/oauth/jwks.
"""

import time
from types import SimpleNamespace

import jwt as pyjwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa

from app import oauth_jwks
from app.config import settings
from app.deps import _role_from_erp_claims


@pytest.fixture
def rsa_keypair():
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    return private_key, private_key.public_key()


def _sign(private_key, claims: dict) -> str:
    return pyjwt.encode(claims, private_key, algorithm="RS256", headers={"kid": "test-kid"})


def _base_claims(**overrides) -> dict:
    claims = {
        "iss": "nexora-erp",
        "aud": settings.erp_token_audience,
        "sub": 42,
        "tid": 7,
        "tipo": "funcionario",
        "scope": "",
        "exp": int(time.time()) + 900,
        "iat": int(time.time()),
    }
    claims.update(overrides)
    return claims


def test_decode_erp_access_token_valido(monkeypatch, rsa_keypair):
    private_key, public_key = rsa_keypair
    monkeypatch.setattr(
        oauth_jwks, "_jwks_client",
        lambda: SimpleNamespace(get_signing_key_from_jwt=lambda _t: SimpleNamespace(key=public_key)),
    )

    token = _sign(private_key, _base_claims())
    payload = oauth_jwks.decode_erp_access_token(token)

    assert payload["sub"] == 42
    assert payload["tid"] == 7


def test_decode_erp_access_token_expirado_e_rejeitado(monkeypatch, rsa_keypair):
    private_key, public_key = rsa_keypair
    monkeypatch.setattr(
        oauth_jwks, "_jwks_client",
        lambda: SimpleNamespace(get_signing_key_from_jwt=lambda _t: SimpleNamespace(key=public_key)),
    )

    token = _sign(private_key, _base_claims(exp=int(time.time()) - 60, iat=int(time.time()) - 120))
    with pytest.raises(pyjwt.PyJWTError):
        oauth_jwks.decode_erp_access_token(token)


def test_decode_erp_access_token_audience_errada_e_rejeitada(monkeypatch, rsa_keypair):
    private_key, public_key = rsa_keypair
    monkeypatch.setattr(
        oauth_jwks, "_jwks_client",
        lambda: SimpleNamespace(get_signing_key_from_jwt=lambda _t: SimpleNamespace(key=public_key)),
    )

    token = _sign(private_key, _base_claims(aud="outro-servico"))
    with pytest.raises(pyjwt.PyJWTError):
        oauth_jwks.decode_erp_access_token(token)


def test_role_from_erp_claims_superadmin():
    assert _role_from_erp_claims({"tipo": "superadmin", "scope": ""}) == "ADMIN_SISTEMA"


def test_role_from_erp_claims_gestor_rh_por_permissao():
    claims = {"tipo": "funcionario", "scope": "recursos-humanos:ver_funcionarios recursos-humanos:aprovar_ausencias"}
    assert _role_from_erp_claims(claims) == "GESTOR_RH"


def test_role_from_erp_claims_wildcard_scope_e_gestor_rh():
    # scope="*" só deveria acontecer para tipo=superadmin na prática (ver
    # scopeStringFromAccess no ERP), mas o mapeamento não deve confiar só em
    # "tipo" vindo intacto — cobre o caso defensivamente.
    assert _role_from_erp_claims({"tipo": "funcionario", "scope": "*"}) == "GESTOR_RH"


def test_role_from_erp_claims_colaborador_sem_permissoes_de_gestao():
    claims = {"tipo": "funcionario", "scope": "recursos-humanos:ver_funcionarios"}
    assert _role_from_erp_claims(claims) == "COLABORADOR"


def test_role_from_erp_claims_scope_vazio_ou_ausente():
    assert _role_from_erp_claims({"tipo": "funcionario"}) == "COLABORADOR"
    assert _role_from_erp_claims({"tipo": "funcionario", "scope": ""}) == "COLABORADOR"
