# Análise Técnica — Implementação da Autenticação Nexora (Access Key / HMAC-SHA256)

> **Projeto:** FaceClock / assiduidade_system_backend  
> **Data:** 2026-08-04  
> **Escopo:** Análise técnica preparatória para migração da autenticação entre sistemas (servidores, integrações e terminais Nexora) de Bearer Token / JWT para credenciais Nexora baseadas em `NEXORA_ACCESS_KEY_ID` + `NEXORA_SECRET_ACCESS_KEY` com assinatura HMAC-SHA256.

---

## 1. Resumo Executivo

O repositório já contém uma **implementação parcial** do mecanismo HMAC Nexora em `app/security/nexora_auth.py`, mas:

- Não segue a especificação exata de headers e mensagem canónica descrita nos requisitos.
- Não possui entidade de base de dados para credenciais (`ApiCredential`).
- Não utiliza Redis para proteção contra replay.
- Não implementa rate limiting por access key.
- Não tem SDK Python (`nexora_sdk`).
- Ainda **não está aplicado** a nenhum endpoint.

A autenticação atual dos endpoints de integração baseia-se em `Authorization: Bearer <token>` (JWT local ou RS256 do ERP) ou em headers de confiança do gateway (`X-Auth-User-Id`, `X-Auth-User-Role`, `X-Auth-Tenant-Id` + `X-Gateway-Secret`). A autenticação de utilizadores humanos (JWT/OAuth) deve ser **mantida**; a alteração destina-se apenas a comunicações serviço-a-serviço, APIs internas e terminais Nexora.

---

## 2. Estado Atual (Baseline)

### 2.1 Estrutura geral do projeto

| Caminho | Função |
|---|---|
| `app/main.py` | Ponto de entrada FastAPI; lifespan, middleware, CORS, routers, health/ready, métricas. |
| `app/config.py` | Classe `Settings` com variáveis de ambiente e validação de segredos em produção. |
| `app/database.py` | Engine SQLAlchemy, `SessionLocal`, `Base`, `get_db()`. |
| `app/models.py` | Modelos SQLAlchemy — atualmente `FaceTemplate` e `FingerprintTemplate`. |
| `app/deps.py` | Resolução de identidade (`get_actor`), `ActorContext`, `apply_tenant`, `require_self_or_manager`. |
| `app/routers/` | Routers FastAPI: `biometric.py`, `fingerprint.py`, `liveness.py`, `audit.py`, `monitoring.py`. |
| `app/services/` | Lógica de negócio: `biometric.py`, `attendance_validation.py`, `liveness_challenge.py`. |
| `app/schemas/` | Pydantic: `requests.py`, `responses.py`, `common.py`. |
| `app/security/` | `encryption.py`, `facial_verification.py`, `nexora_auth.py` (novo/untracked), `__init__.py`. |
| `app/erp_client.py` | Cliente HTTP para chamadas ao Nexora ERP. |
| `app/oauth_jwks.py` | Verificação local RS256 de access tokens do ERP via JWKS. |
| `app/limiter.py` | Rate-limiting com `slowapi` (chave = IP remoto). |
| `alembic/` | Migrações Alembic. |
| `tests/` | Testes pytest: `test_api.py`, `test_encryption.py`, `test_facial_verification.py`, `test_oauth_jwks.py`. |

### 2.2 Autenticação atual

A identidade do chamador é resolvida em `app/deps.py:get_actor` por esta ordem:

1. **JWT Bearer** (`Authorization: Bearer <token>`):
   - Tenta decifrar como JWT local HS256 (`_decode_local_jwt`), usando `JWT_SECRET_KEY`.
   - Se falhar, valida localmente como access token RS256 do ERP via JWKS (`_validate_local_jwt` → `app/oauth_jwks.py:decode_erp_access_token`).
   - O ERP publica chaves em `ERP_BASE_URL/oauth/jwks`; audiência esperada `ERP_TOKEN_AUDIENCE` (default `nexora-api`).

2. **Headers de confiança do gateway** (`X-Auth-User-Id`, `X-Auth-User-Role`, `X-Auth-Tenant-Id`):
   - Exigem `X-Gateway-Secret`, comparado com `GATEWAY_SHARED_SECRET` via `hmac.compare_digest`.
   - Em produção, `assert_production_secrets()` exige `GATEWAY_SHARED_SECRET` configurado.

### 2.3 Onde o Bearer Token / autenticação atual é usado

| Endpoint | Router | Segurança atual |
|---|---|---|
| `POST /api/v1/biometric/enroll` | `app/routers/biometric.py` | `Depends(get_actor)` |
| `POST /api/v1/biometric/verify` | `app/routers/biometric.py` | `Depends(get_actor)` |
| `POST /api/v1/fingerprint/enroll` | `app/routers/fingerprint.py` | `Depends(get_actor)` |
| `POST /api/v1/fingerprint/identify` | `app/routers/fingerprint.py` | `Depends(get_actor)` |
| `DELETE /api/v1/fingerprint/enroll/{user_id}` | `app/routers/fingerprint.py` | `Depends(get_actor)` |
| `POST /api/v1/liveness/challenge` | `app/routers/liveness.py` | `Depends(get_actor)` |
| `POST /api/v1/liveness/verify` | `app/routers/liveness.py` | `Depends(get_actor)` |
| `GET /api/v1/audit/logs` | `app/routers/audit.py` | `Authorization: Bearer` (proxy ERP) |
| `GET /metrics` | `app/routers/monitoring.py` | Público |
| `GET /health`, `GET /ready` | `app/main.py` | Público |

### 2.4 O que já existe de HMAC Nexora

O ficheiro `app/security/nexora_auth.py` (novo, untracked) implementa:

- Headers de assinatura:
  - `X-Nexora-Access-Key-Id`
  - `X-Nexora-Signature-Timestamp`
  - `X-Nexora-Signature-Nonce`
  - `X-Nexora-Signature`
- String canónica: `<timestamp>\n<nonce>\n<METHOD>\n<path>\n<sha256(body)>`
- Validação: timestamp dentro do TTL (default 300s), nonce não reutilizado, access key id conhecido, HMAC coincide.
- Dependência FastAPI: `require_nexora_signature`.
- Leitura de `NEXORA_ACCESS_KEY_ID`, `NEXORA_SECRET_ACCESS_KEY`, `NEXORA_SIGNATURE_TTL_SECONDS` em `app/config.py`.

**Nota:** o novo mecanismo ainda **não está aplicado** em nenhum router; existe apenas como dependência exportada.

### 2.5 Base de dados e infraestrutura

- **Modelos atuais:** apenas `FaceTemplate` e `FingerprintTemplate`.
- **Entidade `Tenant`:** não existe no FaceClock atual; `tenant_id` é apenas uma coluna `String(36)` nos modelos biométricos.
- **Redis:** não está configurado nem utilizado.
- **Rate limiting:** `slowapi` por IP remoto (`app/limiter.py`).
- **Logging:** o middleware `structured_logging_middleware` em `app/main.py` regista apenas `method`, `path`, `status_code`, `duration_ms` e `request_id` — não regista headers nem body, pelo que o risco atual de vazamento de segredos é baixo.

---

## 3. Gaps Críticos em Relação aos Requisitos

| Requisito | Estado atual | Gap |
|---|---|---|
| **Headers de assinatura** | `X-Nexora-Access-Key-Id`, `X-Nexora-Signature-Timestamp`, `X-Nexora-Signature-Nonce`, `X-Nexora-Signature` | O pedido exige `X-Nexora-Access-Key`, `X-Nexora-Timestamp`, `X-Nexora-Nonce`, `X-Nexora-Content-SHA256`, `X-Nexora-Signature` e opcionalmente `X-Nexora-Auth-Version`. |
| **Mensagem canónica** | `timestamp\nnonce\nmethod\npath\nbody_hash` | O pedido exige `METHOD\nREQUEST_PATH\nCANONICAL_QUERY_STRING\nTIMESTAMP\nNONCE\nBODY_SHA256`. |
| **Entidade `ApiCredential`** | Não existe | Necessário criar tabela com `access_key_id`, `encrypted_secret_access_key`, `tenant_id`, `permissions`, `status`, `expires_at`, `revoked_at`, etc. |
| **Cifragem da secret em repouso** | Chave única em `.env` | A secret deve ser cifrada com chave mestra externa à BD. |
| **Proteção replay** | `set()` em memória (10 000 nonces) | O pedido exige Redis com TTL ≥ 5 min. |
| **Rate limiting por credencial** | Apenas por IP | Necessário limitar também por access key. |
| **Permissões por credencial** | Não existe | Necessário verificar `biometric:enroll`, `biometric:verify`, etc. |
| **SDK Python `nexora_sdk`** | Não existe | Terá de ser criado do zero. |
| **Mensagens de erro genéricas** | Erros específicos ("Access Key Id invalida", "Assinatura invalida") | O pedido exige não revelar qual elemento falhou. |
| **Validação HTTPS em produção** | Não existe | Recomenda-se rejeitar pedidos HTTP em `ENVIRONMENT=production`. |
| **Endpoints `/api/attendance/*`** | Não existem routers de attendance | Apenas existe validação interna de método de assiduidade em `app/services/attendance_validation.py`. |

---

## 4. Decisões de Arquitetura a Tomar

Antes de implementar, é necessário decidir:

1. **Coexistência ou substituição?**
   - A autenticação Nexora deve **substituir** `get_actor` nos endpoints de integração, ou **coexistir** (permitir Bearer **OU** Nexora)?
   - Recomendação: nos endpoints chamados por servidores/terminais/integrações, exigir **apenas** Nexora HMAC. Manter JWT/OAuth para utilizadores humanos.

2. **Tenant da credencial vs. tenant do recurso**
   - `tenant_id` nos modelos biométricos é uma string sem FK. A `ApiCredential` terá `tenant_id`. A dependência de autenticação deve injetar o `tenant_id` da credencial no contexto do request, para que `apply_tenant()` continue a filtrar dados corretamente.

3. **Origem da `NEXORA_API_URL` no SDK**
   - O SDK aponta para o FaceClock ou para o ERP? O exemplo do requisito (`NEXORA_API_URL=https://api.nexora.co.mz` + `client.biometric.verify(...)`) sugere que aponta para o **FaceClock**.

4. **Provisionamento de credenciais**
   - Quem cria as credenciais? Endpoint administrativo, comando CLI, ou sincronização vinda do ERP?

5. **Cifragem da secret em repouso**
   - Usar `cryptography.fernet.Fernet` com chave mestra vinda de `NEXORA_CREDENTIAL_ENCRYPTION_KEY` (recomendado) ou AES-256-GCM manual.

6. **Redis obrigatório ou opcional?**
   - Em produção: obrigatório. Em dev/testes: `fakeredis` ou memória com aviso.

7. **Assinatura com body vazio**
   - Documentar: `body = b""` e `BODY_SHA256 = hashlib.sha256(b"").hexdigest()`.

8. **Canonical query string**
   - Normalizar com `urllib.parse.urlencode(sorted(params.items()), doseq=True)`, alinhando RFC 3986 para evitar divergências entre SDK e backend.

---

## 5. Plano de Implementação Proposto

### Fase 1 — Modelos de dados e migrações
- Criar entidade `ApiCredential` em `app/models.py`.
- Criar migração Alembic para tabela `api_credentials`.
- Adicionar `NEXORA_CREDENTIAL_ENCRYPTION_KEY` a `app/config.py` e `.env.example`.

### Fase 2 — Serviço de gestão de credenciais
- Criar `app/services/api_credentials.py` com:
  - `create_credential(tenant_id, name, permissions, expires_at=None)` → gera `access_key_id` e `secret_access_key`, cifra e guarda; devolve a secret **apenas uma vez**.
  - `rotate_credential(credential_id, overlap_seconds=300)`.
  - `revoke_credential(credential_id)`.
  - `get_active_credential(access_key_id)`.

### Fase 3 — Refazer autenticação HMAC no backend
- Substituir/refatorar `app/security/nexora_auth.py` para:
  - Usar os headers e mensagem canónica exatos dos requisitos.
  - Consultar a tabela `ApiCredential`.
  - Validar status, expiração, revogação e permissões.
  - Validar timestamp (≤ 5 min).
  - Verificar replay via Redis.
  - Devolver mensagens de erro genéricas.
  - Atualizar `last_used_at` sem logar segredos.
- Adicionar validação HTTPS em produção.

### Fase 4 — Rate limiting por credencial
- Estender `app/limiter.py` com key_func combinada (IP + access key) ou implementar rate limit customizado na dependência Nexora.

### Fase 5 — Proteger endpoints de integração
- Aplicar `Depends(require_nexora_signature, permission="...")` aos endpoints de biometria, impressão digital e liveness.
- Manter `/health`, `/ready`, `/metrics` públicos.
- Criar/proteger futuros `/api/v1/attendance/*`.

### Fase 6 — SDK Python `nexora_sdk`
- Criar estrutura:
  ```
  nexora_sdk/
  ├── __init__.py
  ├── client.py
  ├── credentials.py
  ├── signer.py
  ├── biometric.py
  ├── attendance.py
  ├── exceptions.py
  └── tests/
  ```
- Implementar resolução de credenciais: parâmetros → env → ficheiro de configuração.
- Implementar serialização JSON determinística e envio HTTP assinado.

### Fase 7 — Testes
- Testes unitários para `signer.py` e `nexora_auth.py`.
- Testes de integração para todos os cenários obrigatórios.
- Usar `fakeredis` para testes de replay/concorrência.

### Fase 8 — Documentação
- Atualizar `.env.example`.
- Criar `docs/NEXORA_AUTH.md` ou secção no README.
- Atualizar `openapi.yaml`.

---

## 6. Ficheiros a Alterar / Criar

### Backend

| Ficheiro | Ação | Notas |
|---|---|---|
| `app/models.py` | Alterar | Adicionar `ApiCredential`. |
| `alembic/versions/<novo>.py` | Criar | Migração para `api_credentials`. |
| `app/config.py` | Alterar | Adicionar `NEXORA_CREDENTIAL_ENCRYPTION_KEY`, `REDIS_URL`, ajustar validações de produção. |
| `app/security/nexora_auth.py` | Substituir/refatorar | Alinhar headers, canónica, BD, Redis, permissões, erros genéricos. |
| `app/security/__init__.py` | Alterar | Exportar novas funções/classes. |
| `app/services/api_credentials.py` | Criar | Criação, rotação, revogação, cifragem. |
| `app/limiter.py` | Alterar | Rate limit por credencial + IP. |
| `app/routers/biometric.py` | Alterar | Trocar `Depends(get_actor)` por Nexora HMAC. |
| `app/routers/fingerprint.py` | Alterar | Idem. |
| `app/routers/liveness.py` | Alterar | Idem. |
| `app/routers/attendance.py` | Criar (se necessário) | Se forem criados endpoints `/api/attendance/*`. |
| `app/main.py` | Alterar | Adicionar validação HTTPS em produção; atualizar routers. |
| `docker-compose.yml` | Alterar | Adicionar serviço Redis; variáveis Redis. |
| `requirements.txt` | Alterar | Adicionar `redis`, `fakeredis` (dev/tests). |
| `.env.example` | Alterar | Adicionar variáveis Nexora e Redis. |

### SDK

| Ficheiro | Ação |
|---|---|
| `nexora_sdk/__init__.py` | Criar |
| `nexora_sdk/client.py` | Criar |
| `nexora_sdk/credentials.py` | Criar |
| `nexora_sdk/signer.py` | Criar |
| `nexora_sdk/biometric.py` | Criar |
| `nexora_sdk/attendance.py` | Criar |
| `nexora_sdk/exceptions.py` | Criar |
| `nexora_sdk/tests/` | Criar |
| `pyproject.toml` (raiz ou `nexora_sdk/`) | Criar |

### Testes e documentação

| Ficheiro | Ação |
|---|---|
| `tests/test_nexora_auth.py` | Criar |
| `tests/test_api_credentials.py` | Criar |
| `tests/test_api.py` | Alterar | Adaptar fixtures para usar HMAC. |
| `README.md` / `docs/NEXORA_AUTH.md` | Criar/atualizar |
| `openapi.yaml` | Regenerar/atualizar |

---

## 7. Mapeamento de Rotas Protegidas

### Endpoints a proteger com Nexora HMAC

| Método | Path | Permissão sugerida |
|---|---|---|
| `POST` | `/api/v1/biometric/enroll` | `biometric:enroll` |
| `POST` | `/api/v1/biometric/verify` | `biometric:verify` |
| `POST` | `/api/v1/fingerprint/enroll` | `fingerprint:enroll` |
| `POST` | `/api/v1/fingerprint/identify` | `fingerprint:identify` |
| `DELETE` | `/api/v1/fingerprint/enroll/{user_id}` | `fingerprint:delete` |
| `POST` | `/api/v1/liveness/challenge` | `liveness:challenge` |
| `POST` | `/api/v1/liveness/verify` | `liveness:verify` |
| `*` | `/api/v1/attendance/*` (futuro) | `attendance:*` |

### Endpoints que devem permanecer públicos

| Método | Path |
|---|---|
| `GET` | `/health` |
| `GET` | `/ready` |
| `GET` | `/metrics` |

### Endpoints com autenticação humana (manter)

| Método | Path | Autenticação atual |
|---|---|---|
| `GET` | `/api/v1/audit/logs` | `Authorization: Bearer` (proxy ERP) |

---

## 8. Riscos e Recomendações

1. **Concorrência na proteção replay** — o `set()` em memória não funciona em múltiplos workers/processos. **Deve usar Redis.**
2. **Chaves default em produção** — `assert_production_secrets()` já exige `NEXORA_ACCESS_KEY_ID` e `NEXORA_SECRET_ACCESS_KEY`; manter esse comportamento.
3. **Logging de segredos** — o middleware atual não loga headers/body, mas garantir que exceções não transportam a secret.
4. **Rotação com overlap** — implementar via `revoked_at` e permitir múltiplas credenciais ativas durante o período de sobreposição.
5. **Compatibilidade com ERP Go** — a string canónica e os nomes dos headers devem ser exatamente iguais no SDK Python e no backend Go. **Alinhar previamente.**
6. **Rate limit por IP insuficiente** — o ERP pode ser o único IP visível; limitar por access key é essencial.
7. **Body vazio** — documentar e testar explicitamente o comportamento quando não há body.

---

## 9. Questões em Aberto

1. **SDK independente ou módulo interno?** Querem publicar `nexora_sdk` no PyPI ou mantê-lo apenas dentro deste repositório?
2. **Provisionamento de credenciais:** como e quem cria as `ApiCredential`? CLI, endpoint admin, ou sincronização automática vinda do ERP?
3. **Coexistência de auth:** a Nexora HMAC substitui totalmente `get_actor` nos endpoints de integração, ou pretende-se aceitar Bearer **OU** HMAC?
4. **`/api/attendance/*`:** existem planos para criar esses endpoints no FaceClock, ou referem-se a endpoints no ERP?
5. **Cifragem da secret:** usar `Fernet` (recomendado) ou AES-256-GCM manual?
6. **Redis em dev:** obrigatório ou usa-se `fakeredis` para facilitar desenvolvimento local?

---

## 10. Próximo Passo Recomendado

Assim que forem confirmadas as decisões acima (especialmente os pontos 1, 2, 3 e 5), a implementação pode avançar na seguinte ordem:

1. Modelo `ApiCredential` + migração Alembic.
2. Refatoração completa de `app/security/nexora_auth.py`.
3. Serviço de gestão de credenciais (`app/services/api_credentials.py`).
4. Proteção dos endpoints de integração.
5. SDK Python `nexora_sdk`.
6. Testes obrigatórios.

---

*Documento gerado para suporte à decisão e planeamento da implementação da autenticação Nexora HMAC no backend FaceClock.*
