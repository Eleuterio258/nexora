# Guia de Deploy em Produção — FaceClock API

> **Data:** 2026-08-04  
> **Aplica-se a:** `assiduidade_system_backend` (Python / FastAPI)

---

## 1. Pré-requisitos

- Docker e Docker Compose instalados no servidor.
- PostgreSQL acessível (pode ser container ou serviço gerido).
- Redis acessível (container incluído no `docker-compose.yml`).
- Traefik ou outro reverse proxy com TLS configurado.
- Domínio apontado para o servidor: `asseduidade.e258tech.tech`.

---

## 2. Gerar Segredos de Produção

As seguintes chaves **devem ser geradas com valores fortes e únicos**. Não reutilize os valores de exemplo.

```bash
# Chave para cifrar templates biométricos (32 bytes)
BIOMETRIC_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Chave mestra para cifrar credenciais Nexora em repouso (32 bytes)
NEXORA_CREDENTIAL_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Segredo partilhado com o ERP para comprovativos faciais (32 bytes)
FACIAL_VERIFICATION_SECRET=$(openssl rand -base64 32)

echo "BIOMETRIC_ENCRYPTION_KEY=$BIOMETRIC_ENCRYPTION_KEY"
echo "NEXORA_CREDENTIAL_ENCRYPTION_KEY=$NEXORA_CREDENTIAL_ENCRYPTION_KEY"
echo "FACIAL_VERIFICATION_SECRET=$FACIAL_VERIFICATION_SECRET"
```

> **Importante:** guarde estes segredos num gestor de passwords ou cofre. A perda da `NEXORA_CREDENTIAL_ENCRYPTION_KEY` impossibilita a recuperação das secrets das credenciais.

---

## 3. Configurar o Ficheiro `.env`

```bash
cp .env.production.example .env
```

Edite `.env` e preencha:

- `DATABASE_URL` — credenciais reais do PostgreSQL.
- `BIOMETRIC_ENCRYPTION_KEY` — valor gerado acima.
- `NEXORA_CREDENTIAL_ENCRYPTION_KEY` — valor gerado acima.
- `FACIAL_VERIFICATION_SECRET` — valor gerado acima (deve coincidir com o backend Go).
- `ERP_BASE_URL` e `ERP_API_KEY` — dados de ligação ao ERP.
- `CORS_ORIGINS` — domínios autorizados (não use `*` em produção).

Exemplo mínimo de `.env`:

```env
ENVIRONMENT=production
DATABASE_URL=postgresql://faceclock:SENHA_DB@pg:5432/faceclock

BIOMETRIC_ENCRYPTION_KEY=...
NEXORA_CREDENTIAL_ENCRYPTION_KEY=...
FACIAL_VERIFICATION_SECRET=...

NEXORA_SIGNATURE_TTL_SECONDS=300
NEXORA_AUTH_VERSION=NEXORA-HMAC-SHA256-V1
NEXORA_HMAC_REQUIRE_HTTPS=true
NEXORA_RATE_LIMIT_PER_KEY=100/minute

REDIS_URL=redis://redis:6379/0

ERP_BASE_URL=https://api.nexora.e258tech.tech
ERP_API_KEY=...

CORS_ORIGINS=https://asseduidade.e258tech.tech
SEED_DATA_ON_STARTUP=false
```

---

## 4. Configurar o Docker Compose

O `docker-compose.yml` já inclui:

- Serviço `redis` com volume persistente.
- Serviço `controle-api` com healthcheck e labels Traefik.
- Rede `backend` externa (deve existir previamente).
- Redirect HTTP → HTTPS.
- TLS via Let's Encrypt (`certresolver=le`).

Criar a rede externa se ainda não existir:

```bash
docker network create backend
```

---

## 5. Construir e Arrancar

```bash
docker compose build --no-cache
docker compose up -d
```

Verificar logs:

```bash
docker compose logs -f controle-api
```

O `entrypoint.sh` executa automaticamente as migrações Alembic antes de iniciar o Uvicorn.

---

## 6. Verificações Pós-Deploy

### 6.1 Healthcheck

```bash
curl https://asseduidade.e258tech.tech/health
```

Deve retornar `{"status":"ok"}` (ou similar).

### 6.2 Validação de Segredos

O arranque falha com `RuntimeError` se algum dos segredos default ainda estiver em uso em produção. Verifique os logs para confirmar que a aplicação subiu sem erros.

### 6.3 Redis

Confirme que o container Redis está a correr e acessível:

```bash
docker compose exec redis redis-cli ping
```

Deve responder `PONG`.

### 6.4 HTTPS

O Traefik deve servir o certificado TLS válido para `asseduidade.e258tech.tech`.

```bash
curl -I https://asseduidade.e258tech.tech/health
```

---

## 7. Criar a Primeira Credencial Nexora

Com o serviço a correr, crie uma credencial para o primeiro tenant/terminal:

```bash
docker compose exec controle-api python - <<'PY'
from app.database import SessionLocal
from app.services.api_credentials import create_credential

db = SessionLocal()
try:
    cred, secret = create_credential(
        db=db,
        tenant_id="tenant_principal",
        name="Terminal Entrada Principal",
        permissions=["biometric:verify", "attendance:create"],
    )
    print("Access Key ID:", cred.access_key_id)
    print("Secret Access Key:", secret)
finally:
    db.close()
PY
```

> **Guarde a `Secret Access Key` — só é mostrada uma vez.**

Configure estas credenciais no cliente/terminal que consome a API.

---

## 8. Configurar o Cliente / Terminal

No terminal ou integração, configure:

```env
NEXORA_ACCESS_KEY_ID=nexora_ak_...
NEXORA_SECRET_ACCESS_KEY=nexora_sk_...
NEXORA_API_URL=https://asseduidade.e258tech.tech
```

Se usar o SDK Python:

```python
from nexora_sdk import NexoraClient

client = NexoraClient()
resultado = client.biometric.verify(
    user_id="usr_123",
    image_base64="...",
)
```

---

## 9. Segurança Recomendada

- **Não exponha a documentação OpenAPI publicamente** em produção, a menos que seja intencional. Considere desativar `DOCS_URL` e `OPENAPI_URL` ou protegê-los.
- **Restrinja o CORS** a domínios específicos; nunca use `*` com `allow_credentials=true`.
- **Mantenha o Redis protegido** — não o exponha publicamente.
- **Rode backups regulares** do PostgreSQL.
- **Monitore tentativas de autenticação falhadas** e alerte em caso de padrões suspeitos.
- **Rode as credenciais periodicamente** usando `rotate_credential()`.
- **Revogue imediatamente** qualquer credencial comprometida.

---

## 10. Troubleshooting

### A aplicação não arranca com "RuntimeError: ... não configurado"

Significa que um dos segredos default ainda está em uso. Verifique `.env` e confirme que `BIOMETRIC_ENCRYPTION_KEY`, `NEXORA_CREDENTIAL_ENCRYPTION_KEY` e `FACIAL_VERIFICATION_SECRET` foram alterados.

### Erro 409 em todos os pedidos

Provavelmente o Redis não está acessível. A validação de nonce falha fechado quando o Redis não responde. Verifique `REDIS_URL` e a conectividade.

### Erro 401 em todos os pedidos

- Verifique se o relógio do cliente está sincronizado (NTP).
- Confirme que está a usar HTTPS (se `NEXORA_HMAC_REQUIRE_HTTPS=true`).
- Verifique se a credencial está ativa e não expirada.
- Confirme que a assinatura está a ser calculada exatamente como o protocolo especifica (body determinístico, query string ordenada).

### Certificado TLS inválido

Verifique se o Traefik tem acesso à internet para o desafio ACME e se o domínio aponta corretamente para o servidor.

---

## 11. Referências

- `docs/NEXORA_AUTH.md` — documentação do protocolo HMAC.
- `ANALISE_AUTENTICACAO_NEXORA.md` — análise técnica detalhada.
- `docker-compose.yml` — orquestração de serviços.
- `Dockerfile` — construção da imagem.
- `entrypoint.sh` — migrações e arranque.
