# Nexora ERP — Backend

API backend do **Nexora ERP**, uma plataforma de gestão empresarial multi-empresa (SaaS)
pensada para o contexto moçambicano — vendas, stock, finanças, recursos humanos e gestão
académica, tudo isolado por tenant (organização cliente).

Para uma visão de funcionalidades orientada a cliente, ver [DOCUMENTACAO_CLIENTE.md](DOCUMENTACAO_CLIENTE.md).

## 🛠️ Stack

- **Linguagem**: Go 1.25
- **Router**: [chi](https://github.com/go-chi/chi) + [go-chi/cors](https://github.com/go-chi/cors)
- **Base de dados**: PostgreSQL via [pgx/v5](https://github.com/jackc/pgx) (pool de conexões)
- **Autenticação**: JWT ([golang-jwt/jwt/v5](https://github.com/golang-jwt/jwt)), com guardas de auth separados por portal (candidato, aluno/encarregado, etc.)
- **Tempo real**: [socket.io](https://github.com/zishang520/socket.io) e um hub WebSocket próprio ([gorilla/websocket](https://github.com/gorilla/websocket)) lado a lado
- **Armazenamento de ficheiros**: local disk ou MinIO/S3 ([minio-go/v7](https://github.com/minio/minio-go)), plugável via `STORAGE_PROVIDER`
- **Notificações push**: Firebase Cloud Messaging (`firebase.google.com/go/v4`)
- **Email**: AWS SES via API nativa ([aws-sdk-go-v2/service/sesv2](https://github.com/aws/aws-sdk-go-v2), mailer próprio em `internal/background/mailer_ses.go`)
- **Migrations**: [golang-migrate](https://github.com/golang-migrate/migrate)
- **Testes**: [testify](https://github.com/stretchr/testify) + [pgxmock](https://github.com/pashagolub/pgxmock) (mock de Postgres para pgx)

## 📁 Estrutura do projeto

```
backend/
├── main.go                  # entrypoint: config, DB, jobs em background, servidor HTTP
├── config/                  # Config struct + Load() a partir de variáveis de ambiente
├── internal/
│   ├── router/               # monta rotas de todos os módulos, CORS, middlewares
│   ├── db/                   # conexão ao Postgres (pgxpool)
│   ├── background/           # jobs recorrentes (notificações, lembretes, limpeza de sessões,
│   │                         # alertas de stock, mensalidades escolares, renovação de assinaturas)
│   ├── middleware/           # auth JWT, auditoria, rate limit, guardas por portal
│   ├── modules/              # domínios de negócio (ver secção Módulos)
│   ├── shared/
│   │   ├── adapters/         # adaptadores entre módulos (ex.: gestão escolar → RH/Financeiro)
│   │   └── contracts/        # interfaces (ports) que os adaptadores implementam
│   ├── storage/               # storage plugável: local disk ou MinIO/S3
│   ├── ws/                    # hub WebSocket (Gorilla), usado a par do socket.io
│   ├── push/                  # notificações push via Firebase Cloud Messaging
│   └── idhash/                 # ofuscação de IDs numéricos expostos na API
├── cmd/
│   ├── broadcast_push/        # CLI: envia push a todos os candidatos de um tenant
│   ├── migrate-storage/       # CLI: migra ficheiros de storage local para o provider configurado
│   └── testrouter/            # smoke test: confirma que router.New() constrói sem falhar
├── migrations/                 # migrations SQL (golang-migrate) + README próprio
├── scripts/                    # scripts de migração e seeds (ver secção Migrations)
├── seeds/                      # seed standalone de demo (escola modelo)
├── Dockerfile
└── go.mod / go.sum
```

## 📦 Módulos (`internal/modules/`)

Comercial/vendas: `crm`, `pos`, `modulo-faturacao`, `assinaturas`, `gestao-clientes`
Operacional: `gestao-produtos`, `gestao-stock`, `compras`, `logistica`, `tarefas`
Financeiro: `contabilidade`, `tesouraria`, `centros-custo`, `multi-moeda`, `impostos`
RH e Recrutamento: `recursos-humanos`, `recrutamento`, `self-service`, `assinatura-digital`
Gestão Escolar: `gestao-escolar` (módulo mais extenso, com portais de aluno/professor/encarregado)
Plataforma: `auth`, `utilizadores`, `empresas`, `auditoria`, `seguranca`, `notifications`, `sistema-configuracao`, `superadmin`, `aprovacoes`

## ⚙️ Configuração (variáveis de ambiente)

| Variável | Default | Descrição |
|---|---|---|
| `DATABASE_URL` | `postgres://postgres:admin@209.126.86.55:5432/nexora_erp?sslmode=disable…` | Connection string, inclui `search_path` com todos os schemas por módulo |
| `PORT` | `8080` | Porta do servidor HTTP |
| `CORS_ORIGIN` | `*` | Origem permitida para CORS |
| `JWT_SECRET` | — | Segredo do JWT de acesso (também usado como salt do `idhash`, deve ficar sincronizado com o frontend PHP) |
| `JWT_REFRESH_SECRET` | — | Segredo do JWT de refresh |
| `JWT_EXPIRES_IN` | `15m` | Validade do token de acesso |
| `JWT_REFRESH_EXPIRES_IN` | `7d` | Validade do token de refresh |
| `AVATAR_MAX_MB` / `AVATAR_DIR` | `2` / `./avatars` | Upload de avatares |
| `RECRUITMENT_TENANT_ID` | `1` | Tenant usado pelo portal de recrutamento |
| `UPLOADS_DIR` / `UPLOAD_MAX_MB` | `./uploads` / `3` | Upload de documentos gerais |
| `GATEWAY_WEBHOOK_SECRET` | — | Validação de webhooks da gateway de pagamentos |
| `FIREBASE_CREDENTIALS_FILE` | `./config/e258tech-d439e.json` | Credenciais do Firebase Admin SDK (push notifications) |
| `NEXORA_PAY_BASE_URL` | `http://nexora-pay:3000` | Gateway Nexora-Pay (M-Pesa/eMola/mKesh) |
| `NEXORA_PAY_API_KEY` / `NEXORA_PAY_SERVICE_ACCOUNT` | — / `gestao-escolar` | Credenciais da gateway |
| `SES_REGION` / `SES_FROM` / `SES_FROM_NAME` | `us-east-1` / — / `Nexora ERP` | Envio de email via AWS SES (credenciais AWS pela cadeia standard do SDK, não por env var própria) |
| `STORAGE_PROVIDER` | `minio` (alt. `local`) | Provider de storage de ficheiros |
| `STORAGE_LOCAL_DIR` / `STORAGE_PUBLIC_URL` | `./uploads` / — | Storage local |
| `MINIO_ENDPOINT` / `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` / `MINIO_BUCKET` / `MINIO_USE_SSL` / `MINIO_REGION` | `localhost:9004` / … / `nexora` / `false` / `us-east-1` | Storage MinIO/S3 |

## 🚀 Como correr localmente

### 1. Base de dados e migrations

Migrations usam o formato do `golang-migrate` (`migrations/*.up.sql` / `*.down.sql`). Ver detalhes em [migrations/README.md](migrations/README.md).

```bash
cd scripts
./run_migrations.sh up        # aplica migrations pendentes
./run_migrations.sh version   # verifica versão atual
./run_migrations.sh down      # reverte a última migration
```

O script lê `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` (com defaults locais) e usa o CLI `migrate` se disponível, ou a imagem Docker `migrate/migrate` como fallback.

> Bases de dados criadas antes da adopção do `golang-migrate` devem correr uma vez `scripts/seed_golang_migrate.sql` antes de usar `run_migrations.sh`.

### 2. Seeds (dados de demonstração)

```bash
psql "$DATABASE_URL" -f scripts/seed_e258tech_completo.sql
psql "$DATABASE_URL" -f seeds/escola_modelo_2026.sql   # demo de escola
```

### 3. Correr o servidor

```bash
go run .
```

Ou compilar:

```bash
go build -o nexora-api .
./nexora-api
```

### 4. Docker

```bash
docker build -t nexora-api .
docker run -p 8080:8080 --env-file .env nexora-api
```

## 🧪 Testes

```bash
go test ./...
```

Os testes usam `pgxmock` para simular o Postgres, sem depender de uma base de dados real.

## 🔧 Ferramentas CLI (`cmd/`)

- `go run ./cmd/broadcast_push -tenant=<id> -title="..." -body="..."` — envia push a todos os candidatos de um tenant
- `go run ./cmd/migrate-storage` — migra ficheiros de storage local para o provider configurado (ex.: MinIO)
- `go run ./cmd/testrouter` — smoke test do router
- `go run ./cmd/send-test-email -to=alguem@exemplo.com` — testa o envio via AWS SES sem subir o servidor

## 📚 Documentação adicional

- [internal/modules/assinatura-digital/README.md](internal/modules/assinatura-digital/README.md) — estado atual, API, segurança e roteiro de conformidade da assinatura digital

- [DOCUMENTACAO_CLIENTE.md](DOCUMENTACAO_CLIENTE.md) — visão de funcionalidades orientada a cliente
- [analise_banco_nexora_erp.md](analise_banco_nexora_erp.md) — análise da base de dados
- [analise_migracao_minio.md](analise_migracao_minio.md) — plano de migração de storage para MinIO
- [analise_modulo_gestao_escolar.md](analise_modulo_gestao_escolar.md) / [relatorio_completo_gestao_escolar.md](relatorio_completo_gestao_escolar.md) — módulo de Gestão Escolar
- [correcoes_aplicadas.md](correcoes_aplicadas.md) — histórico de correções aplicadas
- [docs/recrutamento_rh_resumo.md](docs/recrutamento_rh_resumo.md) — fluxo de contratação (Recrutamento → RH)
- [migrations/README.md](migrations/README.md) — detalhes do sistema de migrations
- [nexora-postman.json](nexora-postman.json) — coleção Postman da API
