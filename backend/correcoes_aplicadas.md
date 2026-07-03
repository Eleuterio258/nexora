# Correções e Melhorias Aplicadas — Backend Nexora

**Data:** 2026-06-29  
**Base de dados:** `nexora_erp` em 127.0.0.1:5432  
**Backend:** Go 1.23 — `D:/projecto/e-258tech/2026/factPro/backend`

---

## 1. Resumo

| # | Área | Descrição | Estado |
|---|---|---|---|
| 1 | Gestão Escolar | Correção de permissões no banco | ✅ |
| 2 | Gestão Escolar | Correção do dashboard (estado/status, strings SQL) | ✅ |
| 3 | Gestão Escolar | Correção de NULL scan em professores | ✅ |
| 4 | Infraestrutura | Ajuste do `search_path` do PostgreSQL | ✅ |
| 5 | Storage | Implementação de camada de abstração MinIO | ✅ |
| 6 | Storage | Refatoração de upload de candidaturas para MinIO | ✅ |
| 7 | Storage | Refatoração de avatares para MinIO | ✅ |
| 8 | Storage | Script de migração local → MinIO | ✅ |

---

## 2. Correções do Módulo Gestão Escolar

### 2.1 Permissões dos cargos

**Banco:** `nexora_erp` — `auth.permissoes_cargo`

```sql
UPDATE auth.permissoes_cargo SET acao='gerir_matriculas' WHERE modulo='gestao-escolar' AND acao='matriculas';
UPDATE auth.permissoes_cargo SET acao='gerir_propinas' WHERE modulo='gestao-escolar' AND acao='propinas';
UPDATE auth.permissoes_cargo SET acao='gerir_presencas' WHERE modulo='gestao-escolar' AND acao='frequencia';
UPDATE auth.permissoes_cargo SET acao='lancar_notas' WHERE modulo='gestao-escolar' AND acao='notas';
UPDATE auth.permissoes_cargo SET acao='ver' WHERE modulo='gestao-escolar' AND acao='turmas-ver';
```

### 2.2 Dashboard escolar

**Ficheiro:** `internal/modules/gestao-escolar/handlers/comunicacao.go`

- `estado='aberto'` → `status IN ('registada','em_analise')`
- `activo` em `school_teachers` → `status='activo'`
- `''valor''` → `'valor'` em todas as strings SQL

### 2.3 Listagem de professores

**Ficheiro:** `internal/modules/gestao-escolar/repositories/teacher.go`

Adicionado `COALESCE(...,'')` para campos nullable:

```go
COALESCE(genero,'') AS genero,
COALESCE(telefone,'') AS telefone,
COALESCE(email,'') AS email,
COALESCE(documento_identificacao,'') AS documento_identificacao,
COALESCE(especialidade,'') AS especialidade,
```

### 2.4 Search path do PostgreSQL

```sql
ALTER ROLE postgres SET search_path TO auth, utilizadores, empresas, clientes, faturacao, financeiro, contabilidade, gestao_escolar, public;
```

---

## 3. Migração para MinIO

### 3.1 Estrutura criada

```
internal/storage/
├── storage.go   # interface Provider + factory
├── local.go     # Provider local em disco
└── minio.go     # Provider MinIO/S3-compatible
```

### 3.2 Interface Provider

```go
type Provider interface {
    Put(ctx context.Context, key string, data []byte, contentType string) (string, error)
    Get(ctx context.Context, key string) (io.ReadCloser, int64, error)
    GetURL(ctx context.Context, key string) (string, error)
    Delete(ctx context.Context, key string) error
    Exists(ctx context.Context, key string) (bool, error)
}
```

### 3.3 Configurações adicionadas

**Ficheiro:** `config/config.go`

```go
StorageProvider   string
StorageLocalDir   string
StoragePublicURL  string
MinioEndpoint     string
MinioAccessKey    string
MinioSecretKey    string
MinioBucket       string
MinioUseSSL       bool
MinioRegion       string
```

**Env variables:**

```bash
STORAGE_PROVIDER=minio        # ou local
STORAGE_LOCAL_DIR=./uploads
STORAGE_PUBLIC_URL=http://localhost:9004/nexora
MINIO_ENDPOINT=localhost:9004
MINIO_ACCESS_KEY=histories
MINIO_SECRET_KEY=histories
MINIO_BUCKET=nexora
MINIO_USE_SSL=false
MINIO_REGION=us-east-1
```

### 3.4 Refatorações

| Handler | Alteração |
|---|---|
| `recrutamento/handlers/public.go` | `saveUpload` usa `h.storage.Put` e devolve key retrocompatível |
| `recrutamento/handlers/candidaturas.go` | `downloadFicheiro` usa `h.storage.Get` |
| `utilizadores/handlers/avatar.go` | Upload/obter/remover avatar usam `h.storage` |
| `internal/router/router.go` | Criação do storage adapter e injeção nos handlers |

### 3.5 Script de migração

**Ficheiro:** `cmd/migrate-storage/main.go`

Migra:
- CVs e cartas de `recrutamento.candidaturas`
- Ficheiros custom de `recrutamento.candidatura_valores_custom`
- Ficheiros de vaga de `recrutamento.candidatura_respostas_vaga`
- Avatares de `utilizadores.user_avatar`

Layout no MinIO:

```
s3://nexora/uploads/tenant-{id}/cv/{ficheiro}
s3://nexora/uploads/tenant-{id}/carta/{ficheiro}
s3://nexora/avatars/user-{id}/{ficheiro}
```

---

## 4. Validação

### 4.1 Gestão Escolar

```
POST /api/auth/login                    → 200
GET  /api/escolar/dashboard             → 200
GET  /api/escolar/dashboard/direction   → 200
GET  /api/escolar/classes?limit=1       → 200
GET  /api/escolar/teachers?limit=1      → 200
GET  /api/escolar/students?limit=1      → 200
GET  /api/escolar/enrollments?limit=1   → 200
GET  /api/escolar/subjects?limit=1      → 200
GET  /api/escolar/years?limit=1         → 200
```

### 4.2 MinIO

Com `STORAGE_PROVIDER=minio`:

```
POST /api/utilizadores/13/avatar        → 200
Resposta: {"url":"http://localhost:9004/nexora/avatars/user-13/user_13_....png"}
```

Ficheiros verificados no bucket `nexora` via AWS CLI.

### 4.3 Storage local

Com `STORAGE_PROVIDER=local`:

```
POST /api/utilizadores/13/avatar        → 200
Resposta: {"url":"/avatars/user-13/user_13_....png"}
```

### 4.4 Migração

Script executado com sucesso. Ficheiros migrados:

```
s3://nexora/uploads/tenant-1/cv/...
s3://nexora/uploads/tenant-1/carta/...
```

---

## 5. Ficheiros Criados/Alterados

### Criados

- `internal/storage/storage.go`
- `internal/storage/local.go`
- `internal/storage/minio.go`
- `cmd/migrate-storage/main.go`
- `analise_modulo_gestao_escolar.md`
- `analise_banco_nexora_erp.md`
- `correcoes_aplicadas.md` (este ficheiro)
- `relatorio_completo_gestao_escolar.md`
- `analise_migracao_minio.md`
- `backup_nexora_erp_20260628_044410.sql`

### Alterados

- `config/config.go`
- `internal/router/router.go`
- `internal/modules/recrutamento/handlers/handler.go`
- `internal/modules/recrutamento/handlers/public.go`
- `internal/modules/recrutamento/handlers/candidaturas.go`
- `internal/modules/utilizadores/handlers/handler.go`
- `internal/modules/utilizadores/handlers/avatar.go`
- `internal/modules/gestao-escolar/handlers/comunicacao.go`
- `internal/modules/gestao-escolar/repositories/teacher.go`

### Alterações no banco

- `auth.permissoes_cargo`
- `search_path` do role `postgres`
- `recrutamento.candidaturas` (paths mantidos)

---

## 6. Como usar MinIO

### 6.1 Iniciar backend (MinIO é default)

```bash
cd D:/projecto/e-258tech/2026/factPro/backend
export DATABASE_URL="postgres://postgres:admin@127.0.0.1:5432/nexora_erp?sslmode=disable"
export JWT_SECRET="change-me-jwt-secret-32chars-min"
export JWT_REFRESH_SECRET="change-me-refresh-secret-32chars"
export PORT="8080"
export MINIO_ENDPOINT="localhost:9004"
export MINIO_ACCESS_KEY="histories"
export MINIO_SECRET_KEY="histories"
export MINIO_BUCKET="nexora"
export MINIO_USE_SSL="false"
export MINIO_REGION="us-east-1"
export STORAGE_PUBLIC_URL="http://localhost:9004/nexora"
./nexora-backend-test.exe
```

### 6.2 Iniciar backend com storage local

```bash
export STORAGE_PROVIDER="local"
export STORAGE_LOCAL_DIR="./uploads"
export STORAGE_PUBLIC_URL=""
./nexora-backend-test.exe
```

### 6.3 Executar migração local → MinIO

```bash
export MINIO_ENDPOINT="localhost:9004"
export MINIO_ACCESS_KEY="histories"
export MINIO_SECRET_KEY="histories"
export MINIO_BUCKET="nexora"
export MINIO_USE_SSL="false"
export MINIO_REGION="us-east-1"
export STORAGE_PUBLIC_URL="http://localhost:9004/nexora"
./migrate-storage.exe
```

---

## 7. Pendências

| # | Problema | Observação |
|---|---|---|
| 1 | `/api/escolar/financial-config` | Retorna 404 — endpoint não exposto |
| 2 | Dados operacionais escolares | 0 alunos, matrículas, notas, ocorrências |
| 3 | Listagem de vagas | Erro 500 (NULL scan semelhante ao professor) |
| 4 | Frontend PHP | Dependência total do backend, sem tratamento de erros |
| 5 | Outros modelos | Revisar scan NULL em students, guardians, etc. |

---

## 8. Conclusão

Foram aplicadas correções críticas no módulo Gestão Escolar e implementada uma camada completa de abstração de storage compatível com MinIO. O sistema está funcional para o utilizador `admin@enigmaschool.mz` tanto com storage local como MinIO, e a migração dos ficheiros existentes foi testada com sucesso.
