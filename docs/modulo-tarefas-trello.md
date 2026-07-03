# Módulo de Gestão de Tarefas (Kanban/Trello) — Nexora ERP

> **Status:** Análise de viabilidade concluída. Próximo passo: implementação MVP.  
> **Data:** 2026-06-23

---

## 1. Resumo Executivo

A adição de um **módulo de Gestão de Tarefas estilo Trello/Kanban** à Nexora ERP é **viável e bem encaixada** na arquitetura atual.

- Não existe hoje nenhum módulo genérico de tarefas.
- O CRM tem apenas "atividades" do tipo `tarefa` aninhadas em leads/oportunidades.
- O Recrutamento tem um pipeline Kanban, mas específico para candidaturas.
- Portanto, há espaço claro para um módulo novo e independente.

**Recomendação:** implementar primeiro o **MVP** (quadros → colunas → cartões → movimento drag & drop) e deixar etiquetas, membros, comentários, anexos e notificações para fases seguintes.

---

## 2. Arquitetura do Projeto

### 2.1 Backend Go

- **Router:** chi, centralizado em `backend/internal/router/router.go`.
- **DB:** PostgreSQL via `pgx/v5/pgxpool`.
- **Padrão de módulo:**
  ```
  backend/internal/modules/<modulo>/handlers/
  ├── handler.go   # struct Handler + New(db, cfg) + helpers
  ├── entidade.go  # CRUD + listagem
  └── outros.go
  ```
- **Permissões:** `mw.RequireAuth(...)` + `mw.RequirePermission(db, "modulo", "acao")`.
- **Listagens:** paginação (`page`, `limit`), filtros por query string, `ILIKE`.
- **Atualizações:** verificam `RowsAffected() == 0` para retornar 404.
- **Transações:** usam `h.db.Begin` para operações com histórico/movimentação.

### 2.2 Frontend PHP

- **Controllers API:** `frontend/src/Controller/Admin/Api/<Modulo>Controller.php`
- **Services:** `frontend/src/Model/Service/<Modulo>/<Modulo>Service.php`
- **Views:** `frontend/src/View/templates/pages/<pagina>.php`
- **Rotas de páginas:** `frontend/src/Routing/AdminRoutes.php`
- **Rotas de API:** `frontend/src/Routing/AdminApiRoutes.php`
- **Permissões:** `frontend/src/View/templates/partials/modules.php` + `AdminApiKernel`
- **Menu:** `frontend/src/View/templates/layouts/top.php`

### 2.3 Base de Dados

- Migrations numeradas em `backend/migrations/`.
- Cada módulo cria seu próprio schema.
- Padrão de tabelas:
  - `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
  - `tenant_id BIGINT NOT NULL`
  - `created_at` / `updated_at` `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`
  - Enums via `CHECK (... IN (...))`
  - JSONB e arrays quando adequado

### 2.4 Docker

- `docker-compose.yml` não inclui serviço Postgres (usa BD externa existente).
- Backend expõe porta `8080`, frontend via Traefik.
- Comunicação interna: `NEXORA_API_URL: http://nexora-api:8080`.

---

## 3. Modelo de Dados Sugerido

### Schema

```sql
CREATE SCHEMA IF NOT EXISTS tarefas;
SET search_path TO tarefas, public;
```

### Tabelas

#### 3.1 Quadros (`quadros`)

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `BIGINT PK` | Identificador |
| `tenant_id` | `BIGINT NOT NULL` | Tenant isolation |
| `titulo` | `VARCHAR(200) NOT NULL` | Nome do quadro |
| `descricao` | `TEXT` | Descrição opcional |
| `cor` | `VARCHAR(7)` | Cor do quadro (hex) |
| `arquivado` | `BOOLEAN DEFAULT FALSE` | Quadro arquivado |
| `created_at` | `TIMESTAMPTZ` | Data de criação |
| `updated_at` | `TIMESTAMPTZ` | Data de atualização |

#### 3.2 Listas / Colunas (`listas`)

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `BIGINT PK` | Identificador |
| `tenant_id` | `BIGINT NOT NULL` | Tenant isolation |
| `quadro_id` | `BIGINT FK → quadros.id` | Quadro pai |
| `titulo` | `VARCHAR(200) NOT NULL` | Nome da coluna |
| `posicao` | `INTEGER DEFAULT 0` | Ordem horizontal |
| `arquivada` | `BOOLEAN DEFAULT FALSE` | Lista arquivada |
| `created_at` | `TIMESTAMPTZ` | Data de criação |
| `updated_at` | `TIMESTAMPTZ` | Data de atualização |

#### 3.3 Cartões (`cartoes`)

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `BIGINT PK` | Identificador |
| `tenant_id` | `BIGINT NOT NULL` | Tenant isolation |
| `lista_id` | `BIGINT FK → listas.id` | Lista/coluna atual |
| `titulo` | `VARCHAR(255) NOT NULL` | Título do cartão |
| `descricao` | `TEXT` | Descrição |
| `posicao` | `INTEGER DEFAULT 0` | Ordem vertical na lista |
| `data_inicio` | `DATE` | Data de início |
| `data_fim` | `DATE` | Data de fim/prazo |
| `prioridade` | `VARCHAR(20)` | `baixa`, `media`, `alta`, `urgente` |
| `etiquetas` | `JSONB DEFAULT '[]'` | IDs de etiquetas (cache) |
| `responsaveis` | `INTEGER[] DEFAULT '{}'` | IDs dos responsáveis |
| `concluido` | `BOOLEAN DEFAULT FALSE` | Cartão concluído |
| `arquivado` | `BOOLEAN DEFAULT FALSE` | Cartão arquivado |
| `created_at` | `TIMESTAMPTZ` | Data de criação |
| `updated_at` | `TIMESTAMPTZ` | Data de atualização |

#### 3.4 Etiquetas (`etiquetas`)

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `BIGINT PK` | Identificador |
| `tenant_id` | `BIGINT NOT NULL` | Tenant isolation |
| `nome` | `VARCHAR(50) NOT NULL` | Nome da etiqueta |
| `cor` | `VARCHAR(7)` | Cor (hex) |
| `created_at` | `TIMESTAMPTZ` | Data de criação |

#### 3.5 Ligação Cartão ↔ Etiqueta (`cartao_etiquetas`)

| Campo | Tipo | Descrição |
|---|---|---|
| `cartao_id` | `BIGINT FK → cartoes.id` | Cartão |
| `etiqueta_id` | `BIGINT FK → etiquetas.id` | Etiqueta |
| `PRIMARY KEY (cartao_id, etiqueta_id)` | | |

#### 3.6 Membros do Quadro (`quadro_membros`)

| Campo | Tipo | Descrição |
|---|---|---|
| `quadro_id` | `BIGINT FK → quadros.id` | Quadro |
| `user_id` | `BIGINT` | Utilizador (auth.users) |
| `papel` | `VARCHAR(20)` | `admin`, `membro`, `espectador` |
| `created_at` | `TIMESTAMPTZ` | Data de adição |
| `PRIMARY KEY (quadro_id, user_id)` | | |

#### 3.7 Atividades / Comentários (`atividades`)

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `BIGINT PK` | Identificador |
| `tenant_id` | `BIGINT NOT NULL` | Tenant isolation |
| `cartao_id` | `BIGINT FK → cartoes.id` | Cartão |
| `user_id` | `BIGINT` | Autor |
| `tipo` | `VARCHAR(20)` | `comentario`, `movimento`, `anexo`, `sistema` |
| `conteudo` | `TEXT NOT NULL` | Texto/atividade |
| `created_at` | `TIMESTAMPTZ` | Data |

#### 3.8 Anexos (`anexos`)

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `BIGINT PK` | Identificador |
| `tenant_id` | `BIGINT NOT NULL` | Tenant isolation |
| `cartao_id` | `BIGINT FK → cartoes.id` | Cartão |
| `nome` | `VARCHAR(255) NOT NULL` | Nome do ficheiro |
| `ficheiro_url` | `VARCHAR(500) NOT NULL` | URL do upload |
| `tamanho_bytes` | `BIGINT` | Tamanho |
| `mime_type` | `VARCHAR(100)` | Tipo MIME |
| `created_at` | `TIMESTAMPTZ` | Data |

### SQL Completo da Migration

```sql
CREATE SCHEMA IF NOT EXISTS tarefas;
SET search_path TO tarefas, public;

CREATE TABLE IF NOT EXISTS quadros (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    cor VARCHAR(7) DEFAULT '#F59E0B',
    arquivado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS listas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    quadro_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    posicao INTEGER NOT NULL DEFAULT 0,
    arquivada BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_listas_quadro FOREIGN KEY (quadro_id) REFERENCES quadros(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cartoes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    lista_id BIGINT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    posicao INTEGER NOT NULL DEFAULT 0,
    data_inicio DATE,
    data_fim DATE,
    prioridade VARCHAR(20) NOT NULL DEFAULT 'media'
        CHECK (prioridade IN ('baixa', 'media', 'alta', 'urgente')),
    etiquetas JSONB NOT NULL DEFAULT '[]',
    responsaveis INTEGER[] NOT NULL DEFAULT '{}',
    concluido BOOLEAN NOT NULL DEFAULT FALSE,
    arquivado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cartoes_lista FOREIGN KEY (lista_id) REFERENCES listas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS etiquetas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(50) NOT NULL,
    cor VARCHAR(7) DEFAULT '#6366F1',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cartao_etiquetas (
    cartao_id BIGINT NOT NULL,
    etiqueta_id BIGINT NOT NULL,
    PRIMARY KEY (cartao_id, etiqueta_id),
    CONSTRAINT fk_cartao_etiquetas_cartao FOREIGN KEY (cartao_id) REFERENCES cartoes(id) ON DELETE CASCADE,
    CONSTRAINT fk_cartao_etiquetas_etiqueta FOREIGN KEY (etiqueta_id) REFERENCES etiquetas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS quadro_membros (
    quadro_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    papel VARCHAR(20) NOT NULL DEFAULT 'membro'
        CHECK (papel IN ('admin', 'membro', 'espectador')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (quadro_id, user_id),
    CONSTRAINT fk_quadro_membros_quadro FOREIGN KEY (quadro_id) REFERENCES quadros(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS atividades (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cartao_id BIGINT NOT NULL,
    user_id BIGINT,
    tipo VARCHAR(20) NOT NULL DEFAULT 'comentario'
        CHECK (tipo IN ('comentario', 'movimento', 'anexo', 'sistema')),
    conteudo TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_atividades_cartao FOREIGN KEY (cartao_id) REFERENCES cartoes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS anexos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cartao_id BIGINT NOT NULL,
    nome VARCHAR(255) NOT NULL,
    ficheiro_url VARCHAR(500) NOT NULL,
    tamanho_bytes BIGINT,
    mime_type VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_anexos_cartao FOREIGN KEY (cartao_id) REFERENCES cartoes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_quadros_tenant_id ON quadros (tenant_id);
CREATE INDEX IF NOT EXISTS idx_quadros_arquivado ON quadros (arquivado);
CREATE INDEX IF NOT EXISTS idx_listas_quadro_id ON listas (quadro_id);
CREATE INDEX IF NOT EXISTS idx_listas_posicao ON listas (quadro_id, posicao);
CREATE INDEX IF NOT EXISTS idx_cartoes_lista_id ON cartoes (lista_id);
CREATE INDEX IF NOT EXISTS idx_cartoes_posicao ON cartoes (lista_id, posicao);
CREATE INDEX IF NOT EXISTS idx_cartoes_responsaveis ON cartoes USING GIN (responsaveis);
CREATE INDEX IF NOT EXISTS idx_cartao_etiquetas_cartao_id ON cartao_etiquetas (cartao_id);
CREATE INDEX IF NOT EXISTS idx_atividades_cartao_id ON atividades (cartao_id);
CREATE INDEX IF NOT EXISTS idx_anexos_cartao_id ON anexos (cartao_id);
```

---

## 4. Permissões Sugeridas

Adicionar em `frontend/src/View/templates/partials/modules.php`:

```php
'tarefas' => [
    'nome'  => 'Tarefas',
    'cor'   => '#F59E0B',
    'acoes' => [
        'ver_quadros'      => 'Ver Quadros',
        'gerir_quadros'    => 'Criar & Editar Quadros',
        'gerir_listas'     => 'Gerir Colunas',
        'gerir_cartoes'    => 'Criar & Editar Cartões',
        'mover_cartoes'    => 'Mover Cartões no Kanban',
        'gerir_etiquetas'  => 'Gerir Etiquetas',
        'gerir_membros'    => 'Gerir Membros',
        'comentar'         => 'Comentar',
        'eliminar_cartoes' => 'Eliminar Cartões',
    ],
],
```

> **Nota:** também será necessário mapear ações genéricas (`ver`, `criar`, `editar`, `eliminar`, `gerir`) para as ações reais do módulo `tarefas` na migration de permissões (`046_permissoes_funcionalidades.sql` ou nova migration).

---

## 5. Endpoints API Go

### 5.1 Quadros

| Método | Endpoint | Permissão |
|---|---|---|
| GET | `/api/tarefas/quadros` | `ver_quadros` |
| GET | `/api/tarefas/quadros/{id}` | `ver_quadros` |
| POST | `/api/tarefas/quadros` | `gerir_quadros` |
| PUT | `/api/tarefas/quadros/{id}` | `gerir_quadros` |
| DELETE | `/api/tarefas/quadros/{id}` | `gerir_quadros` |
| POST | `/api/tarefas/quadros/{id}/arquivar` | `gerir_quadros` |

### 5.2 Listas

| Método | Endpoint | Permissão |
|---|---|---|
| POST | `/api/tarefas/quadros/{id}/listas` | `gerir_listas` |
| PUT | `/api/tarefas/listas/{id}` | `gerir_listas` |
| DELETE | `/api/tarefas/listas/{id}` | `gerir_listas` |
| POST | `/api/tarefas/listas/{id}/reordenar` | `gerir_listas` |

### 5.3 Cartões

| Método | Endpoint | Permissão |
|---|---|---|
| GET | `/api/tarefas/cartoes` | `ver_quadros` |
| GET | `/api/tarefas/cartoes/{id}` | `ver_quadros` |
| POST | `/api/tarefas/listas/{id}/cartoes` | `gerir_cartoes` |
| PUT | `/api/tarefas/cartoes/{id}` | `gerir_cartoes` |
| PUT | `/api/tarefas/cartoes/{id}/mover` | `mover_cartoes` |
| DELETE | `/api/tarefas/cartoes/{id}` | `eliminar_cartoes` |
| POST | `/api/tarefas/cartoes/{id}/concluir` | `mover_cartoes` |

### 5.4 Etiquetas, Membros, Comentários, Anexos

| Recurso | Método | Endpoint | Permissão |
|---|---|---|---|
| Etiquetas | CRUD | `/api/tarefas/etiquetas` | `gerir_etiquetas` |
| Etiquetas do cartão | POST/DELETE | `/api/tarefas/cartoes/{id}/etiquetas` | `gerir_cartoes` |
| Membros do quadro | POST/DELETE | `/api/tarefas/quadros/{id}/membros` | `gerir_membros` |
| Atividades | GET/POST | `/api/tarefas/cartoes/{id}/atividades` | `ver_quadros` / `comentar` |
| Anexos | POST/DELETE | `/api/tarefas/cartoes/{id}/anexos` | `gerir_cartoes` |

---

## 6. Frontend PHP

### 6.1 Páginas Sugeridas

| Rota (`AdminRoutes.php`) | View | Descrição |
|---|---|---|
| `/nexora/tarefas` | `tarefas.php` | Lista de quadros do tenant |
| `/nexora/tarefas/quadro` | `tarefas_quadro.php` | Vista Kanban de um quadro |
| `/nexora/tarefas/cartao` | `tarefas_cartao.php` | Detalhe do cartão |
| `/nexora/tarefas/etiquetas` | `tarefas_etiquetas.php` | Gestão de etiquetas |

### 6.2 Endpoints PHP (`AdminApiRoutes.php`)

```php
'quadro_save'        => ['module' => 'tarefas', 'action' => 'gerir_quadros'],
'quadro_delete'      => ['module' => 'tarefas', 'action' => 'gerir_quadros'],
'quadro_arquivar'    => ['module' => 'tarefas', 'action' => 'gerir_quadros'],
'lista_save'         => ['module' => 'tarefas', 'action' => 'gerir_listas'],
'lista_delete'       => ['module' => 'tarefas', 'action' => 'gerir_listas'],
'lista_reordenar'    => ['module' => 'tarefas', 'action' => 'gerir_listas'],
'cartao_save'        => ['module' => 'tarefas', 'action' => 'gerir_cartoes'],
'cartao_mover'       => ['module' => 'tarefas', 'action' => 'mover_cartoes'],
'cartao_concluir'    => ['module' => 'tarefas', 'action' => 'mover_cartoes'],
'cartao_delete'      => ['module' => 'tarefas', 'action' => 'eliminar_cartoes'],
'etiqueta_save'      => ['module' => 'tarefas', 'action' => 'gerir_etiquetas'],
'etiqueta_delete'    => ['module' => 'tarefas', 'action' => 'gerir_etiquetas'],
'membro_save'        => ['module' => 'tarefas', 'action' => 'gerir_membros'],
'membro_remover'     => ['module' => 'tarefas', 'action' => 'gerir_membros'],
'atividade_save'     => ['module' => 'tarefas', 'action' => 'comentar'],
'anexo_save'         => ['module' => 'tarefas', 'action' => 'gerir_cartoes'],
'anexo_delete'       => ['module' => 'tarefas', 'action' => 'gerir_cartoes'],
```

### 6.3 Menu

Adicionar em `frontend/src/View/templates/layouts/top.php`:

```php
$canTarefas = $app->session->canModule('tarefas');
if ($canTarefas) { /* menu Tarefas */ }
```

---

## 7. Plano de Implementação

### Fase 1 — MVP (recomendada)

1. **Backend**
   - Criar migration `backend/migrations/048_tarefas.sql`.
   - Criar `backend/internal/modules/tarefas/handlers/`:
     - `handler.go`
     - `quadros.go`
     - `listas.go`
     - `cartoes.go`
   - Registar rotas em `backend/internal/router/router.go`.
   - Testar com `go build ./...` e `go vet ./...`.

2. **Frontend**
   - Criar `TarefasService` e `TarefasController`.
   - Adicionar módulo em `modules.php`.
   - Adicionar rotas em `AdminRoutes.php` e `AdminApiRoutes.php`.
   - Adicionar menu em `top.php`.
   - Criar views:
     - `tarefas.php` (lista de quadros)
     - `tarefas_quadro.php` (Kanban com drag & drop)
     - `tarefas_cartao.php` (detalhe do cartão)

3. **Permissões**
   - Atualizar migration de permissões para mapear ações genéricas para ações reais de `tarefas`.
   - Inserir permissões padrão em `auth.permissoes_tipo` se necessário.

### Fase 2 — Funcionalidades avançadas

- Etiquetas globais do tenant
- Membros do quadro com papéis
- Comentários e atividades
- Anexos de ficheiros
- Notificações (deadlines, menções)
- Filtros e pesquisa avançada
- Integração futura com CRM (cartão referenciar lead/oportunidade)

---

## 8. Estrutura de Ficheiros Esperada

```text
backend/
├── migrations/
│   └── 048_tarefas.sql
└── internal/modules/tarefas/handlers/
    ├── handler.go
    ├── quadros.go
    ├── listas.go
    ├── cartoes.go
    ├── etiquetas.go
    ├── membros.go
    ├── atividades.go
    └── anexos.go

frontend/src/
├── Controller/Admin/Api/
│   └── TarefasController.php
├── Model/Service/Tarefas/
│   └── TarefasService.php
├── View/templates/pages/
│   ├── tarefas.php
│   ├── tarefas_quadro.php
│   ├── tarefas_cartao.php
│   └── tarefas_etiquetas.php
├── View/templates/partials/modules.php  # adicionar módulo
├── View/templates/layouts/top.php        # adicionar menu
├── Routing/AdminRoutes.php               # adicionar rotas de página
└── Routing/AdminApiRoutes.php            # adicionar rotas de API
```

---

## 9. Considerações de Segurança

- Todas as queries SQL devem filtrar por `tenant_id = $user.TenantID`.
- Utilizar sempre `mw.RequireAuth` antes de `mw.RequirePermission`.
- Superadmin (`tipo = 'superadmin'`) ignora verificações de permissão automaticamente.
- Validar enums no backend (ex.: prioridade, papel do membro).
- Verificar ownership do quadro/lista/cartão antes de atualizar/eliminar.
- Sanitizar inputs de descrição/comentários no frontend antes de enviar.

---

## 10. Próximos Passos

1. Revisar e aprovar este plano.
2. Implementar backend MVP (migration + handlers + rotas).
3. Implementar frontend MVP (views + drag & drop).
4. Testar com superadmin e utilizador de cargo limitado.
5. Iterar para funcionalidades avançadas.
