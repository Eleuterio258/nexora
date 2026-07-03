# Análise de Migração para MinIO — Backend Nexora

**Data:** 2026-06-28  
**Escopo:** Backend Go — Storage de ficheiros  
**Objetivo:** Migrar uploads locais (`./uploads`, `./avatars`) para MinIO/S3-compatible object storage

---

## 1. Resumo Executivo

O backend Nexora opera hoje com **storage local em disco**. Apenas **dois endpoints** fazem upload real de ficheiros:

1. **Recrutamento** — CVs, cartas de motivação e documentos customizados de candidaturas
2. **Utilizadores** — avatares de perfil

Todos os outros módulos apenas **persistem URLs** em colunas `ficheiro_url`, `cv_ficheiro`, etc. O upload propriamente dito é assumido como feito externamente.

**Não existe integração atual com S3, MinIO ou object storage.**

A migração é **simples e de baixo risco** porque a superfície de upload real é pequena. A estratégia recomendada é criar uma camada de abstração de storage com adapter pattern, mantendo compatibilidade com storage local por omissão.

---

## 2. Configuração Atual de Storage

### 2.1 `config/config.go`

| Campo | Tipo | Default | Env | Uso |
|---|---|---|---|---|
| `UploadsDir` | `string` | `"./uploads"` | `UPLOADS_DIR` | Diretório local de uploads |
| `UploadMaxMB` | `int64` | `3` | `UPLOAD_MAX_MB` | Tamanho máximo de CV/carta |
| `AvatarDir` | `string` | `"./avatars"` | `AVATAR_DIR` | Diretório local de avatares |
| `AvatarMaxMB` | `int64` | `2` | `AVATAR_MAX_MB` | Tamanho máximo de avatar |

### 2.2 `.env.example`

```bash
UPLOADS_DIR=./uploads
UPLOAD_MAX_MB=3
AVATAR_DIR=./avatars
AVATAR_MAX_MB=2
```

**Não há variáveis de S3/MinIO.**

---

## 3. Pontos Reais de Upload

### 3.1 Recrutamento — Candidaturas Públicas

**Ficheiro:** `internal/modules/recrutamento/handlers/public.go`

| Função | Linha | Descrição |
|---|---|---|
| `saveUpload` | `214-248` | Função genérica de upload: valida tamanho, extensão, Content-Type, gera nome e grava em disco |
| `SubmeterCandidatura` | `296-589` | Endpoint público de candidatura |

**Detalhes:**
- Diretório: `./uploads/cv`
- Nome gerado: `{prefixo}_{YYYYMMDD_HHMMSS}_{hex(4)}.{ext}`
- Prefixos: `cv`, `carta`, `custom_...`, `vaga_...`
- Path relativo guardado na BD: `cv/<nome>`

**Tipos permitidos:**

| Campo | Extensões | Máx. |
|---|---|---|
| CV | `pdf` | `UploadMaxMB` |
| Carta | `pdf`, `doc`, `docx` | `UploadMaxMB` |
| Ficheiros custom | `pdf`, `doc`, `docx`, `jpg`, `jpeg`, `png` | `UploadMaxMB` |
| Ficheiros por vaga | `pdf`, `doc`, `docx`, `jpg`, `jpeg`, `png` | `UploadMaxMB` |

### 3.2 Utilizadores — Avatar

**Ficheiro:** `internal/modules/utilizadores/handlers/avatar.go`

| Função | Linha | Descrição |
|---|---|---|
| `UploadAvatar` | `27-89` | Recebe `multipart/form-data`, campo `avatar` |
| `ObterAvatar` | `16-25` | Devolve URL do avatar |
| `RemoverAvatar` | `91-109` | Apaga registo e ficheiro local |

**Detalhes:**
- Diretório: `./avatars`
- Formatos: JPEG, PNG
- Nome: `user_<userID>_<timestamp>.jpg|.png`
- URL guardada: `/avatars/<filename>`

---

## 4. Pontos de Download

| Módulo | Ficheiro | Função | Linha |
|---|---|---|---|
| Recrutamento | `candidaturas.go` | `downloadFicheiro` | `493-516` |
| Recrutamento | `candidaturas.go` | `DownloadCV` | `518-520` |
| Recrutamento | `candidaturas.go` | `DownloadCarta` | `522-524` |

**Nota:** o router Go **não expõe FileServer estático** para `/uploads/*` nem `/avatars/*`. O acesso depende de proxy reverso.

---

## 5. URLs/Paths Guardados na Base de Dados

| Schema.tabela | Coluna | Tipo de ficheiro |
|---|---|---|
| `recrutamento.candidaturas` | `cv_ficheiro` | CV |
| `recrutamento.candidaturas` | `carta_ficheiro` | Carta |
| `recrutamento.candidatura_valores_custom` | `ficheiro` | Documentos custom |
| `recrutamento.candidatura_respostas_vaga` | `ficheiro` | Documentos por vaga |
| `utilizadores.user_avatar` | `ficheiro_url` | Avatar |
| `empresas.company_documents` | `ficheiro_url` | Documentos empresa |
| `clientes.customer_documents` | `ficheiro_url` | Documentos cliente |
| `produtos.product_images` | `ficheiro_url` | Imagens produto |
| `rh.contratos` | `ficheiro_url` | Contratos |
| `rh.documentos_funcionario` | `ficheiro_url` | Documentos RH |
| `impostos.tax_certificates` | `ficheiro_url` | Certificados fiscais |
| `chat_mensagens` | `ficheiro_url` | Ficheiros chat |
| `rh.justificacoes` | `ficheiro_url` | Justificações |
| `gestao_escolar.school_students` | `fotografia_url` | Fotos alunos |

---

## 6. Estrutura de Ficheiros Local

```text
uploads/
└── cv/
    ├── carta_20260611_093812_76082967.pdf
    ├── cv_20260625_100124_f9d578ac.pdf
    ├── cv_20260626_130629_46194d67.pdf
    └── ...
```

- **Total estimado:** 8 ficheiros em `./uploads/cv/`
- **Avatares:** diretório `./avatars/` criado em runtime

---

## 7. Estratégia de Migração para MinIO

### 7.1 Princípios

1. **Retrocompatibilidade:** default continua a ser storage local.
2. **Adapter pattern:** camada de abstração isolada.
3. **Migração gradual:** ficheiros locais podem ser movidos para MinIO sem parar o sistema.
4. **URLs estáveis:** o frontend continua a receber URLs servíveis.

### 7.2 Arquitetura proposta

```
┌─────────────┐     ┌─────────────────────┐     ┌─────────┐
│   Cliente   │────▶│  Backend Nexora     │────▶│  MinIO  │
│  (Frontend) │     │  (storage adapter)  │     │ (S3 API)│
└─────────────┘     └─────────────────────┘     └─────────┘
                            │
                            ▼
                     ┌────────────┐
                     │ PostgreSQL │
                     │  (metadados)│
                     └────────────┘
```

### 7.3 Novo pacote `internal/storage/`

```go
package storage

import "context"

type Provider interface {
    Put(ctx context.Context, key string, data []byte, contentType string) (url string, error)
    GetURL(ctx context.Context, key string) (string, error)
    Delete(ctx context.Context, key string) error
    Exists(ctx context.Context, key string) (bool, error)
}
```

Implementações:
- `LocalProvider` — compatibilidade com o atual
- `MinioProvider` — usa `github.com/minio/minio-go/v7`

### 7.4 Configuração nova

Adicionar ao `config.Config`:

```go
StorageProvider string
MinioEndpoint   string
MinioAccessKey  string
MinioSecretKey  string
MinioBucket     string
MinioUseSSL     bool
MinioRegion     string
```

Env variables:

```bash
STORAGE_PROVIDER=local        # ou minio
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=nexora
MINIO_USE_SSL=false
MINIO_REGION=af-south-1
```

### 7.5 Layout de bucket no MinIO

```
s3://nexora/
  uploads/
    tenant-{id}/
      cv/
      cartas/
      custom/
      vaga/
  avatars/
    user-{id}/
```

### 7.6 Passos de implementação

1. Criar `internal/storage` com interface + providers local e MinIO.
2. Adicionar configurações sem alterar defaults.
3. Refatorar `public.go` (recrutamento) para usar adapter.
4. Refatorar `avatar.go` (utilizadores) para usar adapter.
5. Adicionar endpoint genérico `/files/*` ou deixar NGINX servir.
6. Criar script de migração `cmd/migrate-storage`.
7. Rodar migração local → MinIO.
8. Alterar `STORAGE_PROVIDER=minio`.

### 7.7 Migração de dados

Script CLI que:

1. Lista todos os ficheiros locais.
2. Calcula a key no MinIO (ex.: `uploads/tenant-1/cv/nome.pdf`).
3. Faz upload para MinIO.
4. Atualiza os caminhos na BD.
5. Regista progresso numa tabela `storage_migration_log`.

---

## 8. Riscos e Considerações

| Risco | Mitigação |
|---|---|
| Quebra de URLs antigas | Manter compatibilidade de leitura; migrar paths na BD |
| Performance de upload grande | Usar streaming multipart direto para MinIO |
| Permissões de acesso a ficheiros | Usar presigned URLs ou proxy com auth |
| Backup | Configurar lifecycle/replicação no MinIO |
| Ficheiros fora do diretório de uploads | Validar canonicalização de paths no download |

---

## 9. Conclusão

A migração para MinIO é **viável e de baixa complexidade** porque:

- Apenas **2 endpoints** fazem upload real.
- Os restantes módulos já trabalham com URLs.
- O volume atual de ficheiros locais é pequeno.
- É possível manter compatibilidade total com storage local.

A abordagem recomendada é a criação de uma camada de abstração de storage (adapter pattern) que permita ativar MinIO gradualmente, sem quebrar deploys existentes.
