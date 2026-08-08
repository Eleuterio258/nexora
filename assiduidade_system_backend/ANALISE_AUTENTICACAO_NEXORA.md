# Análise da Nova Autenticação Nexora HMAC

> **Backend:** `assiduidade_system_backend` (Python / FastAPI)  
> **Data:** 2026-08-04  
> **Escopo:** Análise técnica do novo protocolo de autenticação serviço-a-serviço baseado em HMAC-SHA256.

---

## 1. Resumo Executivo

A autenticação do backend Python foi completamente refatorada. O modelo anterior baseado em **JWT/Bearer + headers de confiança do gateway** foi substituído por um protocolo próprio de assinatura de pedidos: **Nexora HMAC-SHA256**.

Cada cliente (terminal, ERP, integração externa) autentica-se usando um par de credenciais:

- `NEXORA_ACCESS_KEY_ID` — identificador público (`nexora_ak_...`).
- `NEXORA_SECRET_ACCESS_KEY` — chave secreta usada apenas localmente para assinar pedidos.

A chave secreta **nunca é enviada pela rede**. Cada pedido leva uma assinatura criptográfica reconstruída e validada pelo servidor.

---

## 2. Protocolo de Assinatura

### 2.1 Headers de Autenticação

```http
X-Nexora-Access-Key: nexora_ak_xxxxxxxxx
X-Nexora-Timestamp: 1785830400
X-Nexora-Nonce: 7d3cb813-3e44-4c94-9ecf-9e1ca710cf11
X-Nexora-Content-SHA256: HASH_SHA256_DO_BODY
X-Nexora-Signature: ASSINATURA_HMAC_SHA256
X-Nexora-Auth-Version: NEXORA-HMAC-SHA256-V1
```

### 2.2 Mensagem Canónica

```text
POST
/api/v1/biometric/verify

1785830400
7d3cb813-3e44-4c94-9ecf-9e1ca710cf11
HASH_SHA256_DO_BODY
```

Estrutura:

```text
METHOD\n
PATH\n
CANONICAL_QUERY_STRING\n
TIMESTAMP\n
NONCE\n
BODY_SHA256
```

A query string é normalizada: parâmetros são ordenados por chave e codificados com URL encoding consistente.

### 2.3 Serialização do Body

O SDK Python serializa o payload de forma determinística:

```python
json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
```

> **Nota:** qualquer diferença na serialização do body invalida a assinatura. Clientes noutras linguagens devem replicar exatamente este comportamento.

### 2.4 Cálculo da Assinatura

```python
signature = hmac.new(
    secret_access_key.encode("utf-8"),
    canonical_message.encode("utf-8"),
    hashlib.sha256,
).hexdigest()
```

A comparação no servidor usa `hmac.compare_digest()` para evitar ataques de timing.

---

## 3. Fluxo de Validação no Backend

Localização principal: `app/security/nexora_auth.py`.

A dependência `_require_nexora_signature(permission)` executa as seguintes validações:

| Ordem | Validação | Detalhe |
|-------|-----------|---------|
| 1 | HTTPS em produção | Rejeita HTTP se `ENVIRONMENT=production` e `NEXORA_HMAC_REQUIRE_HTTPS=true` |
| 2 | Headers obrigatórios | Verifica presença de todos os headers Nexora |
| 3 | Timestamp | Tolerância de `NEXORA_SIGNATURE_TTL_SECONDS` (padrão 300s) |
| 4 | Nonce | Armazenado no Redis com `SET NX EX`; reutilização retorna `409 CONFLICT` |
| 5 | Credencial ativa | Busca em `api_credentials`; rejeita revogadas ou expiradas |
| 6 | Hash do body | Compara SHA-256 do body recebido com `X-Nexora-Content-SHA256` |
| 7 | HMAC | Reconstrói mensagem canónica e valida assinatura |
| 8 | Permissões | Verifica se a permissão exigida está na credencial (`403` se negado) |
| 9 | Tenant | Retorna `ActorContext(role="SYSTEM", tenant_id=...)`, isolando por tenant |
| 10 | Último uso | Atualiza `last_used_at` |

Erros de autenticação são genéricos (`401`) para não revelar qual camada falhou.

---

## 4. Gestão de Credenciais

Localização: `app/services/api_credentials.py`.

### 4.1 Operações Disponíveis

| Função | Descrição |
|--------|-----------|
| `create_credential()` | Gera `access_key_id` e `secret_access_key`, cifra a secret com Fernet e guarda na BD. A secret só é devolvida uma vez. |
| `get_active_credential()` | Recupera credencial ativa, verifica expiração/revogação e decifra a secret. |
| `revoke_credential()` | Revoga imediatamente uma credencial. |
| `rotate_credential()` | Cria nova credencial e define expiração curta na antiga (`overlap_seconds`, padrão 300s). |
| `touch_last_used()` | Atualiza o timestamp de último uso. |

### 4.2 Cifra em Repouso

A chave secreta é cifrada com **Fernet** usando `NEXORA_CREDENTIAL_ENCRYPTION_KEY`. A chave mestra aceita:

- Uma chave Fernet válida (32 bytes em base64 url-safe).
- Uma string arbitrária, da qual é derivada uma chave de 32 bytes via SHA-256.

---

## 5. Modelo de Dados

Nova tabela: `api_credentials`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID PK | Identificador interno |
| `access_key_id` | `String(64)`, unique, indexed | Identificador público |
| `encrypted_secret_access_key` | `String(255)` | Chave secreta cifrada com Fernet |
| `name` | `String(150)`, nullable | Nome amigável da credencial |
| `tenant_id` | `String(36)`, indexed | Isolamento multi-tenant |
| `permissions` | `JSON` | Lista de permissões (ex.: `["biometric:verify"]`)
| `status` | `String(20)` | `active` ou `revoked` |
| `created_at` | datetime | Data de criação |
| `expires_at` | datetime, nullable | Data de expiração |
| `last_used_at` | datetime, nullable | Último uso |
| `revoked_at` | datetime, nullable | Data de revogação |

Migração Alembic: `alembic/versions/7ea9ac864a65_add_api_credentials.py`.

---

## 6. SDK Python (`nexora_sdk/`)

Cliente oficial para consumir a API Nexora/FaceClock.

### 6.1 Uso Básico

```python
from nexora_sdk import NexoraClient

client = NexoraClient()

# Verificação facial
resultado = client.biometric.verify(
    user_id="usr_123",
    image_base64="BASE64_DA_IMAGEM",
)

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

### 6.2 Resolução de Credenciais

Ordem de precedência:

1. Parâmetros do construtor.
2. Variáveis de ambiente (`NEXORA_ACCESS_KEY_ID`, `NEXORA_SECRET_ACCESS_KEY`, `NEXORA_API_URL`).
3. Ficheiro de configuração `./.nexora/credentials` ou `~/.nexora/credentials` (formato INI).

### 6.3 Estrutura do SDK

| Ficheiro | Responsabilidade |
|----------|------------------|
| `client.py` | Cliente principal e requisições HTTP |
| `signer.py` | Cálculo da assinatura HMAC-SHA256 |
| `credentials.py` | Resolução de credenciais |
| `biometric.py` | Operações biométricas (enroll/verify) |
| `attendance.py` | Operações de assiduidade (ponto de extensão) |
| `exceptions.py` | Exceções customizadas |

---

## 7. Rotas Protegidas

As rotas protegidas usam a dependência `require_nexora_signature("<permissão>")`:

| Método | Path | Permissão |
|--------|------|-----------|
| `POST` | `/api/v1/biometric/enroll` | `biometric:enroll` |
| `POST` | `/api/v1/biometric/verify` | `biometric:verify` |
| `POST` | `/api/v1/fingerprint/enroll` | `fingerprint:enroll` |
| `POST` | `/api/v1/fingerprint/identify` | `fingerprint:identify` |
| `DELETE` | `/api/v1/fingerprint/enroll/{user_id}` | `fingerprint:delete` |
| `POST` | `/api/v1/liveness/challenge` | `liveness:challenge` |
| `POST` | `/api/v1/liveness/verify` | `liveness:verify` |
| `GET` | `/api/v1/audit/logs` | `audit:read` |

Rotas públicas: `/health`, `/ready`, `/metrics`.

---

## 8. Configurações e Variáveis de Ambiente

### Backend (`app/config.py`)

```env
# Chave mestra para cifrar credenciais em repouso (obrigatória em produção)
NEXORA_CREDENTIAL_ENCRYPTION_KEY=change-me-nexora-credential-encryption-key

# Tolerância de relógio para timestamp HMAC (segundos)
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

### Cliente SDK

```env
NEXORA_ACCESS_KEY_ID=nexora_ak_xxxxxxxxx
NEXORA_SECRET_ACCESS_KEY=nexora_sk_xxxxxxxxx
NEXORA_API_URL=https://api.nexora.co.mz
```

A função `assert_production_secrets()` falha alto se as chaves default ainda estiverem em uso em produção.

---

## 9. Pontos Fortes

- **Elimina JWT/JWKS** e headers de confiança frágeis.
- **Assinatura por pedido** evita replay (nonce + timestamp).
- **Segredos cifrados em repouso** com Fernet.
- **Isolamento por tenant** através do `tenant_id` da credencial.
- **Rate limit por access key + IP** via `app/limiter.py`.
- **Erros genéricos** dificultam reconhecimento de falhas por atacantes.
- **SDK próprio** facilita integração Python.
- **Rotação de credenciais** com período de overlap.

---

## 10. Pontos de Atenção e Recomendações

### 10.1 Dependência do Redis

A validação de nonce depende do Redis. Se o Redis falhar, `_consume_nonce()` retorna `False` e o pedido é rejeitado. É um comportamento seguro, mas pode causar indisponibilidade total se o Redis ficar inacessível.

> **Recomendação:** monitorar Redis e considerar cache local de fallback apenas se o risco de aceitar replay for tolerável.

### 10.2 Sem Endpoint de Criação de Credenciais

Atualmente as credenciais só podem ser criadas via serviço/CLI (`create_credential`). Não existe endpoint administrativo.

> **Recomendação:** implementar endpoint protegido (ex.: com role `ADMIN_SISTEMA`) para criação/gerenciamento de credenciais.

### 10.3 Revogação e Nonces Antigos

Uma credencial revogada rejeita novos pedidos, mas nonces antigos ainda ocupam espaço no Redis até expirar (TTL).

> **Recomendação:** considerar limpeza ou TTL ajustado conforme volume de pedidos.

### 10.4 Reconsumo do Body no FastAPI

O código lê `await request.body()` e depois re-injeta o body via `_receive` para que o parser Pydantic possa processá-lo novamente. É um padrão comum, mas pode afetar middleware que também consuma o body.

> **Recomendação:** validar comportamento com todos os middlewares ativos.

### 10.5 Inconsistência de Formato do Nonce

- Backend (`nexora_auth.py`): nonce gerado com `secrets.token_hex(16)` (32 caracteres hex).
- SDK (`signer.py`): nonce gerado com `uuid.uuid4()` (UUID v4).

Funcionalmente ambos são únicos, mas o protocolo não impõe formato fixo.

> **Recomendação:** padronizar o formato do nonce no protocolo para evitar problemas de interoperabilidade.

### 10.6 Query String em Pedidos GET

O SDK suporta query string (`AttendanceClient.list()`), mas usa `urlencode` diretamente sem ordenar os parâmetros. Como o backend normaliza a query string ordenando por chave, pode haver divergência se os parâmetros não forem enviados ordenados.

> **Recomendação:** garantir que o SDK ordene os parâmetros antes de assinar ou que o backend reordene a query string recebida antes da validação. Verificar cobertura de testes para GET com múltiplos parâmetros.

### 10.7 Logging

O código cuidadosamente evita logar segredos. Manter esta prática em futuras alterações.

---

## 11. Testes

| Ficheiro | Descrição |
|----------|-----------|
| `tests/test_nexora_auth.py` | Valida assinatura válida, access key desconhecida, assinatura inválida, body alterado, timestamp expirado, nonce reusado, credencial revogada |
| `tests/test_api.py` | Reescrito para usar HMAC |
| `tests/test_api_credentials.py` | Testes da gestão de credenciais |
| `nexora_sdk/tests/test_signer.py` | Testes unitários da assinatura |

Resultado reportado na documentação: **41 passed**.

---

## 12. Conclusão

A nova autenticação **Nexora HMAC-SHA256** representa uma melhoria significativa de segurança em relação ao modelo JWT anterior. O protocolo é robusto, bem documentado e acompanhado de SDK próprio. A arquitetura com credenciais por tenant, cifra em repouso, proteção contra replay e rate limiting proporciona uma base sólida para comunicação serviço-a-serviço.

Os principais trabalhos pendentes são: endpoint administrativo para gestão de credenciais, padronização do formato do nonce e revisão da ordenação de parâmetros em query strings.

---

## 13. Referências

- `app/security/nexora_auth.py`
- `app/services/api_credentials.py`
- `app/models.py`
- `app/config.py`
- `app/redis_client.py`
- `nexora_sdk/client.py`
- `nexora_sdk/signer.py`
- `nexora_sdk/credentials.py`
- `docs/NEXORA_AUTH.md`
- `ANALISE-PROTOCOLO-NEXORA-AUTH.md`
- `alembic/versions/7ea9ac864a65_add_api_credentials.py`
