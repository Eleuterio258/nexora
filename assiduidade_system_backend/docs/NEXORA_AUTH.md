# Autenticação Nexora HMAC — Documentação de Utilização

> **Versão:** 1.0.0  
> **Data:** 2026-08-04  
> **Escopo:** Autenticação unificada do FaceClock via Nexora HMAC.

---

## 1. Visão Geral

O FaceClock usa exclusivamente **Nexora HMAC-SHA256** para autenticar todos os pedidos protegidos. As autenticações anteriores (JWT/Bearer e headers de confiança do gateway) foram removidas.

Cada integração/terminal usa credenciais:

- `NEXORA_ACCESS_KEY_ID` — identificador público.
- `NEXORA_SECRET_ACCESS_KEY` — chave secreta usada apenas localmente para assinar.

A chave secreta **nunca é enviada pela rede**. Cada pedido leva uma assinatura criptográfica que o backend valida comparando-a com uma assinatura reconstruída.

---

## 2. Variáveis de Ambiente

### Backend (`app/config.py` / `.env.example`)

```env
# Chave mestra para cifrar as credenciais em repouso (obrigatória em produção)
NEXORA_CREDENTIAL_ENCRYPTION_KEY=change-me-nexora-credential-encryption-key

# Tolerância de relógio para o timestamp HMAC (segundos)
NEXORA_SIGNATURE_TTL_SECONDS=300

# Versão do protocolo
NEXORA_AUTH_VERSION=NEXORA-HMAC-SHA256-V1

# Rejeitar HTTP em produção
NEXORA_HMAC_REQUIRE_HTTPS=true

# Limite de chamadas por access key + IP
NEXORA_RATE_LIMIT_PER_KEY=100/minute

# Redis para proteção contra replay
REDIS_URL=redis://localhost:6379/0
```

### Cliente (SDK)

```env
NEXORA_ACCESS_KEY_ID=nexora_ak_xxxxxxxxx
NEXORA_SECRET_ACCESS_KEY=nexora_sk_xxxxxxxxx
NEXORA_API_URL=https://api.nexora.co.mz
```

---

## 3. Criar Credenciais no Backend

As credenciais são criadas via serviço `app/services/api_credentials.py`:

```python
from sqlalchemy.orm import Session
from app.services.api_credentials import create_credential

cred, secret = create_credential(
    db=db_session,
    tenant_id="tenant_123",
    name="Terminal Entrada Principal",
    permissions=["biometric:verify", "attendance:create"],
    expires_at=None,  # opcional
)

print("Access Key ID:", cred.access_key_id)
print("Secret Access Key (mostrar apenas uma vez):", secret)
```

A secret é cifrada com Fernet usando `NEXORA_CREDENTIAL_ENCRYPTION_KEY` antes de ser guardada.

---

## 4. Usar o SDK Python

### Instalação local

```bash
pip install -e ./nexora_sdk
```

### Exemplo

```python
from nexora_sdk import NexoraClient

client = NexoraClient()

# Verificação facial
resultado = client.biometric.verify(
    user_id="usr_123",
    image_base64="BASE64_DA_IMAGEM",
)
print(resultado["match"])

# Enrollment
client.biometric.enroll(
    user_id="usr_123",
    captures=[
        {"image_base64": "...", "angle": "front"},
        {"image_base64": "...", "angle": "left"},
        {"image_base64": "...", "angle": "right"},
    ],
)
```

### Credenciais via parâmetros

```python
client = NexoraClient(
    access_key_id="nexora_ak_xxxxxxxxx",
    secret_access_key="nexora_sk_xxxxxxxxx",
    base_url="https://api.nexora.co.mz",
)
```

---

## 5. Implementar Cliente noutra Linguagem

O protocolo é independente de linguagem. Envie estes headers:

```http
X-Nexora-Access-Key: nexora_ak_xxxxxxxxx
X-Nexora-Timestamp: 1785830400
X-Nexora-Nonce: 7d3cb813-3e44-4c94-9ecf-9e1ca710cf11
X-Nexora-Content-SHA256: HASH_SHA256_DO_BODY
X-Nexora-Signature: ASSINATURA_HMAC_SHA256
X-Nexora-Auth-Version: NEXORA-HMAC-SHA256-V1
```

### Mensagem canónica

```text
POST
/api/biometric/verify

1785830400
7d3cb813-3e44-4c94-9ecf-9e1ca710cf11
HASH_SHA256_DO_BODY
```

### Body JSON determinístico

```python
json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
```

Consulte `ANALISE-PROTOCOLO-NEXORA-AUTH.md` para exemplos completos em **Go, Java e C#**.

---

## 6. Rotas Protegidas

| Método | Path | Permissão |
|---|---|---|
| `POST` | `/api/v1/biometric/enroll` | `biometric:enroll` |
| `POST` | `/api/v1/biometric/verify` | `biometric:verify` |
| `POST` | `/api/v1/fingerprint/enroll` | `fingerprint:enroll` |
| `POST` | `/api/v1/fingerprint/identify` | `fingerprint:identify` |
| `DELETE` | `/api/v1/fingerprint/enroll/{user_id}` | `fingerprint:delete` |
| `POST` | `/api/v1/liveness/challenge` | `liveness:challenge` |
| `POST` | `/api/v1/liveness/verify` | `liveness:verify` |
| `GET` | `/api/v1/audit/logs` | `audit:read` |

### Rotas públicas

| Método | Path |
|---|---|
| `GET` | `/health` |
| `GET` | `/ready` |
| `GET` | `/metrics` |

---

## 7. Ficheiros Alterados / Criados

### Backend

| Ficheiro | Ação |
|---|---|
| `app/models.py` | Adicionado `ApiCredential` |
| `alembic/versions/7ea9ac864a65_add_api_credentials.py` | Criado |
| `app/config.py` | Adicionadas variáveis Nexora/Redis; removidas variáveis JWT/OAuth |
| `app/security/nexora_auth.py` | Refatorado para HMAC com BD + Redis |
| `app/security/__init__.py` | Exporta `NexoraAuth`, `require_nexora_signature` |
| `app/security/encryption.py` | Corrigido `encrypt_text`/`decrypt_text` com base64 |
| `app/services/api_credentials.py` | Criado |
| `app/redis_client.py` | Criado |
| `app/limiter.py` | Rate limit por access key + IP |
| `app/deps.py` | Permite role `SYSTEM`; removida dependência JWT |
| `app/routers/biometric.py` | Protegido com Nexora HMAC |
| `app/routers/fingerprint.py` | Protegido com Nexora HMAC |
| `app/routers/liveness.py` | Protegido com Nexora HMAC |
| `app/oauth_jwks.py` | **Removido** |
| `requirements.txt` | Adicionado `redis`, `fakeredis`; removidas libs JWT |
| `.env.example` | Atualizado |
| `docker-compose.yml` | Adicionado serviço Redis; removidas variáveis JWT/gateway |

### SDK

| Ficheiro | Ação |
|---|---|
| `nexora_sdk/__init__.py` | Criado |
| `nexora_sdk/client.py` | Criado |
| `nexora_sdk/credentials.py` | Criado |
| `nexora_sdk/signer.py` | Criado |
| `nexora_sdk/biometric.py` | Criado |
| `nexora_sdk/attendance.py` | Criado |
| `nexora_sdk/exceptions.py` | Criado |
| `nexora_sdk/tests/test_signer.py` | Criado |

### Testes

| Ficheiro | Ação |
|---|---|
| `tests/conftest.py` | Criado (fixtures partilhadas) |
| `tests/test_api.py` | Reescrito para usar HMAC |
| `tests/test_api_credentials.py` | Criado |
| `tests/test_nexora_auth.py` | Criado |
| `tests/test_oauth_jwks.py` | **Removido** |

---

## 8. Resultados dos Testes

```text
platform win32 -- Python 3.14.2, pytest-8.4.2, pluggy-1.6.0
rootdir: D:\projecto\e-258tech\2026\factPro\assiduidade_system_backend
plugins: anyio-4.14.1, cov-5.0.0
collected 41 items

nexora_sdk	ests	est_signer.py ....
tests	est_api.py ..........
tests	est_api_credentials.py .......
tests	est_encryption.py ...........
tests	est_facial_verification.py .
tests	est_nexora_auth.py .......

======================= 41 passed, 7 warnings in 17.07s =======================
```

---

## 9. Notas de Segurança

- A `NEXORA_SECRET_ACCESS_KEY` nunca é enviada pela rede.
- As secrets são cifradas em repouso com `NEXORA_CREDENTIAL_ENCRYPTION_KEY`.
- Cada credencial está associada a um tenant.
- Timestamps fora de 5 minutos são rejeitados.
- Nonces reutilizados são rejeitados via Redis (TTL 5 min).
- Comparação de assinaturas usa `hmac.compare_digest()`.
- Erros de autenticação são genéricos (não revelam qual elemento falhou).
- Em produção, pedidos HMAC devem chegar por HTTPS.

---

## 10. Próximos Passos Sugeridos

1. Implementar endpoint/admin para criação de credenciais (atualmente só via serviço/CLI).
2. Publicar `nexora_sdk` no PyPI se for usar fora deste repo.
3. Criar exemplos oficiais de assinatura em Go, Java e C#.
4. Adicionar monitorização de tentativas de autenticação falhadas.
