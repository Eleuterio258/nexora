# Guia de Deploy em Produção — Nexora ERP (Backend Go)

> **Data:** 2026-08-04  
> **Stack:** Go 1.25 + PostgreSQL + MinIO + Traefik

---

## 1. Visão Geral

O backend Go (ERP) é construído a partir de `./backend/Dockerfile` e orquestrado pelo `docker-compose.yml` na raiz do projecto (`/root/nexora`).

Partilha a mesma base de dados PostgreSQL (`nexora_erp` em `209.126.86.55`) com o FaceClock (Python), mas usa schemas separados definidos no `search_path`.

---

## 2. Variáveis de Ambiente

As variáveis são lidas de `/root/nexora/.env` (usado pelo `docker-compose.yml` da raiz).

### Segredos críticos (obrigatórios em produção)

| Variável | Descrição | Onde mais é usada |
|----------|-----------|-------------------|
| `JWT_SECRET` | Assina tokens de acesso | Frontend PHP (`JWT_SECRET` deve ser igual) |
| `JWT_REFRESH_SECRET` | Assina tokens de refresh | Apenas backend Go |
| `FACIAL_VERIFICATION_SECRET` | Valida comprovativos faciais do FaceClock | **Deve ser igual** em `assiduidade_system_backend/.env` |
| `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` | Credenciais do MinIO | MinIO server |
| `GATEWAY_WEBHOOK_SECRET` | Valida webhooks de pagamento | Gateway de pagamento |

### Gerar segredos

```bash
cd /root/nexora
export JWT_SECRET=$(openssl rand -hex 32)
export JWT_REFRESH_SECRET=$(openssl rand -hex 32)
export FACIAL_VERIFICATION_SECRET=$(openssl rand -base64 32)
export GATEWAY_WEBHOOK_SECRET=$(openssl rand -hex 32)
export MINIO_ACCESS_KEY=$(openssl rand -hex 16)
export MINIO_SECRET_KEY=$(openssl rand -hex 32)

echo "JWT_SECRET=$JWT_SECRET"
echo "JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET"
echo "FACIAL_VERIFICATION_SECRET=$FACIAL_VERIFICATION_SECRET"
echo "GATEWAY_WEBHOOK_SECRET=$GATEWAY_WEBHOOK_SECRET"
echo "MINIO_ACCESS_KEY=$MINIO_ACCESS_KEY"
echo "MINIO_SECRET_KEY=$MINIO_SECRET_KEY"
```

> **Importante:** o `FACIAL_VERIFICATION_SECRET` gerado para o ERP deve ser copiado exactamente para o ficheiro `assiduidade_system_backend/.env` na variável com o mesmo nome.

---

## 3. Configurar `/root/nexora/.env`

```bash
cd /root/nexora
cp .env.production.example .env
nano .env
```

Configurações mínimas de produção:

```env
ENVIRONMENT=production
APP_ENV=production
DATABASE_URL=postgres://postgres:Plane%40mento1@209.126.86.55:5432/nexora_erp?sslmode=disable&options=-csearch_path%3Dauth%2Cutilizadores%2Cempresas%2Cauditoria%2Csistema_configuracao%2Cclientes%2Cprodutos%2Cstock%2Cfaturacao%2Crecrutamento%2Ccrm%2Cpos%2Crh%2Ccontabilidade%2Ccentros_custo%2Ccompras%2Cfinanceiro%2Ctesouraria%2Clogistica%2Cimpostos%2Cmulti_moeda%2Cassinaturas%2Cnotifications%2Cseguranca%2Cgestao_escolar%2Cpublic

JWT_SECRET=...
JWT_REFRESH_SECRET=...
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

FACIAL_VERIFICATION_SECRET=...

PORT=8080
CORS_ORIGIN=https://nexora.e258tech.tech
PLATFORM_BASE_DOMAIN=nexora.e258tech.tech
NEXORA_PUBLIC_API_URL=https://api.nexora.e258tech.tech

STORAGE_PROVIDER=minio
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
MINIO_BUCKET=nexoraerp
MINIO_USE_SSL=false
MINIO_REGION=us-east-1

SES_REGION=us-east-1
SES_FROM=noreply@e258tech.tech
SES_FROM_NAME=Nexora ERP
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...

SIGNATURE_ALLOW_INSECURE_PROVIDER=true
GATEWAY_WEBHOOK_SECRET=...

NEXORA_PAY_BASE_URL=https://pay.e258tech.tech
NEXORA_PAY_API_KEY=...
NEXORA_PAY_SERVICE_ACCOUNT=gestao-escolar
```

---

## 4. Build e Deploy

```bash
cd /root/nexora
docker compose build api
docker compose up -d api
```

Verificar logs:

```bash
docker compose logs -f api
```

---

## 5. Verificações Pós-Deploy

### Healthcheck

```bash
curl https://api.nexora.e258tech.tech/health
```

### JWKS (chaves OAuth2)

```bash
curl https://api.nexora.e258tech.tech/oauth/jwks
```

Deve devolver uma chave RS256 válida. Se a directoria `./data/oauth-keys` estiver vazia e `OAUTH_ALLOW_GENERATED_KEY=false`, o servidor recusa arrancar.

---

## 6. Integração com FaceClock

### Segredo partilhado

O valor de `FACIAL_VERIFICATION_SECRET` no ERP deve ser **exactamente igual** ao de `assiduidade_system_backend/.env`.

### URL do FaceClock

O ERP usa `FACECLOCK_BASE_URL` (default: `https://asseduidade.e258tech.tech`) para redirecionar gestores RH para enrollment biométrico.

---

## 7. Notas de Segurança

- Nunca commits do `.env`.
- Em produção real, desactivar `SIGNATURE_ALLOW_INSECURE_PROVIDER` e usar um provider PKI reconhecido (ex.: INTIC).
- Configurar `sslmode=require` na `DATABASE_URL` se o PostgreSQL suportar TLS.
- Proteger o MinIO — não expor publicamente.
- Fazer backup periódico do volume `api_oauth_keys`; se estas chaves mudarem, todos os access tokens OAuth2 já emitidos deixam de validar.

---

## 8. Troubleshooting

### `ENVIRONMENT=production exige segredos reais para: JWT_SECRET, ...`

Um dos segredos ainda tem o valor por omissão. Verifica `.env`.

### `connection refused` para a base de dados

Verifica se `209.126.86.55:5432` está acessível a partir do container:

```bash
docker compose exec api nc -zv 209.126.86.55 5432
```

### `MinIO` não acessível

Confirma que o container MinIO está na rede `backend` e que as credenciais estão correctas.

---

## 9. Ficheiros Relacionados

- `/root/nexora/docker-compose.yml` — orquestração
- `/root/nexora/backend/Dockerfile` — imagem Go
- `/root/nexora/backend/config/config.go` — definição de configurações
- `/root/nexora/assiduidade_system_backend/.env` — configuração do FaceClock
