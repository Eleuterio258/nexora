"""
Router de autenticacao — vazio propositadamente.

O login/refresh deixou de existir no FaceClock (Fase 6 da integracao com o
Nexora ERP): a app Android autentica-se directamente no ERP
(`POST /api/auth/login`), que emite um JWT proprio. O FaceClock valida esse
JWT delegando em `GET /api/auth/gateway/validate` (ver `app/deps.py`,
`erp_client.validate_bearer_token`), em vez de emitir/validar os seus proprios
tokens de login por password local.

Ver CONTRATO-INTEGRACAO-ERP.md secção 8.4.
"""

from fastapi import APIRouter

router = APIRouter(tags=["Auth"])
