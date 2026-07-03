# Plano de Implementação — Módulos Configuráveis, Dependências e Features

**Projecto:** Nexora ERP  
**Data:** 2026-06-24  
**Estado:** Planeamento  

---

## Contexto

O Nexora ERP é um SaaS multi-tenant. Cada organização tem necessidades distintas e não utiliza todos os módulos da plataforma da mesma forma. Este plano define a implementação de:

1. **Catálogo de módulos** — substituir lista hardcoded por tabela DB
2. **Dependências entre módulos** — enforçar integridade ao activar/desactivar
3. **Funcionalidades configuráveis** — sub-features por módulo, por tenant
4. **Entitlement por plano** — plano contratado define o que está disponível
5. **Fluxos de aprovação** — processos com aprovação em múltiplos níveis

---

## Estado Actual do Sistema

### O que já existe e funciona

| Componente | Tabela / Ficheiro | Estado |
|---|---|---|
| Activação de módulos por tenant | `saas.tenant_modules` | ✅ Produção |
| Enforcement de módulos (Go) | `rbac.go:loadModulosDesativados` | ✅ Produção |
| Invalidação de cache (PHP) | `AdminSession::syncModulos` | ✅ Produção |
| RBAC por cargo | `auth.permissoes_cargo` | ✅ Produção |
| Planos de subscrição | `saas.plans` | ✅ Parcial |

### O que existe mas não está ligado

| Componente | Tabela | Problema |
|---|---|---|
| Feature flags por tenant | `sistema_configuracao.tenant_feature_flags` | 0 linhas, 0 handlers Go |
| Config por módulo | `saas.tenant_modules.config jsonb` | Gravado, nunca lido |
| Limites por plano | `saas.plans.limites jsonb` | Definido, nunca enforçado |

### O que não existe

- `saas.module_catalog` — lista de módulos está hardcoded em Go (`modules.go:88`)
- `saas.module_dependencies` — sem grafo de dependências
- `saas.feature_catalog` — sem definição de sub-features por módulo
- `saas.plan_modules` — planos não têm lista de módulos incluídos
- Qualquer tabela de aprovações

---

## Arquitectura Alvo

```
┌─────────────────────────────────────────────────────────┐
│                    CAMADA DE CATÁLOGO                    │
│  saas.module_catalog     saas.feature_catalog            │
│  saas.module_dependencies  saas.plan_modules             │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                 CAMADA DE ACTIVAÇÃO (por tenant)         │
│  saas.tenant_modules (ativo, config jsonb)               │
│  sistema_configuracao.tenant_feature_flags               │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                    CAMADA DE SESSÃO                      │
│  GET /api/auth/me/acesso → { modulos[], features[] }     │
│  AdminSession: canModule() + canFeature()                │
└─────────────────────────────────────────────────────────┘
```

---

## Fase 1 — Catálogo de Módulos + Dependências

**Duração estimada:** 5 dias  
**Migration:** `058_module_catalog.sql`

### 1.1 Tabelas

```sql
-- Catálogo master de módulos (substitui slice hardcoded em Go)
CREATE TABLE saas.module_catalog (
  key        VARCHAR(60)  PRIMARY KEY,
  nome       VARCHAR(150) NOT NULL,
  categoria  VARCHAR(60)  NOT NULL,
  descricao  TEXT,
  icone      VARCHAR(60),
  ativo      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Grafo de dependências (DAG — sem ciclos)
CREATE TABLE saas.module_dependencies (
  modulo    VARCHAR(60) NOT NULL REFERENCES saas.module_catalog(key) ON DELETE CASCADE,
  requires  VARCHAR(60) NOT NULL REFERENCES saas.module_catalog(key) ON DELETE CASCADE,
  PRIMARY KEY (modulo, requires),
  CHECK (modulo <> requires)
);
```

### 1.2 Dados — Catálogo (22 módulos)

| key | nome | categoria |
|---|---|---|
| `clientes` | Clientes | comercial |
| `vendas` | Vendas | comercial |
| `faturacao` | Faturação | comercial |
| `crm` | CRM | comercial |
| `pos` | POS | comercial |
| `assinaturas` | Assinaturas | comercial |
| `stock` | Stock | operacional |
| `compras` | Compras | operacional |
| `logistica` | Logística | operacional |
| `financeiro` | Financeiro | financeiro |
| `tesouraria` | Tesouraria | financeiro |
| `contabilidade` | Contabilidade | financeiro |
| `impostos` | Impostos | financeiro |
| `multi-moeda` | Multi-Moeda | financeiro |
| `centros-custo` | Centros de Custo | financeiro |
| `recursos-humanos` | Recursos Humanos | rh |
| `pedido-ferias` | Gestão de Férias | rh |
| `recrutamento` | Recrutamento | rh |
| `gestao-escolar` | Gestão Escolar | plataforma |
| `notificacoes` | Notificações | plataforma |
| `auditoria` | Auditoria | plataforma |
| `seguranca` | Segurança | plataforma |
| `sistema-configuracao` | Configurações | plataforma |

### 1.3 Dados — Grafo de Dependências

```
clientes ──────────┬─── faturacao ──┬─── impostos
                   │                └─── multi-moeda
                   ├─── vendas
                   ├─── crm
                   └─── assinaturas ──── faturacao

stock ─────────────┬─── compras
                   ├─── logistica
                   └─── pos

financeiro ────────┬─── tesouraria
                   └─── contabilidade ──── centros-custo

recursos-humanos ──┬─── pedido-ferias
                   └─── recrutamento
```

### 1.4 Alterações Go

**`modules.go` — `ListarModulosDisponiveis`**
- Ler de `saas.module_catalog WHERE ativo = TRUE ORDER BY categoria, nome`
- Incluir `categoria`, `descricao`, `icone` na resposta
- Remover slice hardcoded

**Ficheiro novo: `module_deps.go`**
```
loadDependenciasDirectas(ctx, modulo) []string
loadDependentes(ctx, tenantID, modulo) []string   // activos para este tenant
resolveCascata(ctx, modulo) []string               // recursivo — tudo o que precisa de activar
validarDAG(ctx, modulo, requires) error            // prevenir ciclos
```

**`modules.go` — `ActualizarModuloTenant`**

Ao **ACTIVAR**:
1. Calcular dependências recursivas via `resolveCascata()`
2. UPSERT em cascata para todas as dependências
3. Resposta: `{ modulo, ativo: true, activated_also: ["clientes"] }`

Ao **DESACTIVAR**:
1. Consultar `loadDependentes()` — módulos activos que dependem deste
2. Se existirem → erro `409` com lista: `"faturacao e crm dependem deste módulo"`
3. Se não → desactivar normalmente

**Endpoints novos (`/api/superadmin/modules/`):**
```
GET    /catalog                      → lista com categoria + deps
GET    /dependencies                 → grafo completo
POST   /dependencies                 → adicionar dependência
DELETE /dependencies/{mod}/{req}     → remover dependência
```

### 1.5 Alterações PHP UI — `superadmin_modules.php`

- Agrupar módulos por categoria (Comercial / Financeiro / RH / ...)
- Badge `requer: clientes` em módulos com dependências
- Modal ao desactivar: "Os módulos faturacao e crm serão afectados"
- Toast ao activar: "Activado. Também activados: clientes"

---

## Fase 2 — Feature Catalog + Funcionalidades por Tenant

**Duração estimada:** 5 dias  
**Migration:** `059_feature_catalog.sql`

### 2.1 Tabelas

```sql
-- Catálogo de funcionalidades por módulo
CREATE TABLE saas.feature_catalog (
  key               VARCHAR(120) PRIMARY KEY,   -- 'rh.ferias', 'crm.leads'
  modulo            VARCHAR(60)  NOT NULL REFERENCES saas.module_catalog(key),
  nome              VARCHAR(150) NOT NULL,
  descricao         TEXT,
  ativo_por_defeito BOOLEAN NOT NULL DEFAULT TRUE,
  configuravel      BOOLEAN NOT NULL DEFAULT FALSE  -- tenant pode alterar?
);

-- Coluna modulo em tenant_feature_flags (para ligar ao catálogo)
ALTER TABLE sistema_configuracao.tenant_feature_flags
  ADD COLUMN IF NOT EXISTS modulo VARCHAR(60);
```

### 2.2 Dados — Feature Catalog

| key | módulo | nome | defeito | configurável |
|---|---|---|---|---|
| `rh.ferias` | recursos-humanos | Gestão de Férias | ✅ | ✅ |
| `rh.avaliacoes` | recursos-humanos | Avaliações de Desempenho | ❌ | ✅ |
| `rh.formacoes` | recursos-humanos | Gestão de Formações | ❌ | ✅ |
| `rh.folha_pagamento` | recursos-humanos | Folha de Pagamento | ✅ | ✅ |
| `rh.disciplinar` | recursos-humanos | Processos Disciplinares | ❌ | ✅ |
| `vendas.orcamentos` | faturacao | Orçamentos | ✅ | ✅ |
| `vendas.encomendas` | faturacao | Encomendas de Venda | ✅ | ✅ |
| `vendas.fatura_direta` | faturacao | Facturação Directa | ✅ | ❌ |
| `vendas.devolucoes` | faturacao | Devoluções / Notas Crédito | ✅ | ✅ |
| `crm.leads` | crm | Gestão de Leads | ✅ | ✅ |
| `crm.oportunidades` | crm | Pipeline de Oportunidades | ✅ | ✅ |
| `crm.atividades` | crm | Actividades e Follow-up | ✅ | ✅ |
| `compras.requisicoes` | compras | Requisições de Compra | ✅ | ✅ |
| `compras.aprovacoes` | compras | Aprovações em Cascata | ❌ | ✅ |
| `stock.alertas` | stock | Alertas de Stock Mínimo | ✅ | ✅ |
| `stock.series` | stock | Números de Série | ❌ | ✅ |
| `cont.ativo_fixo` | contabilidade | Gestão de Activo Fixo | ❌ | ✅ |

### 2.3 Alterações Go

**`rbac.go` — `UserAccess` e `LoadUserAccess`**

```go
type UserAccess struct {
    // campos existentes...
    Features []string `json:"features"`  // ["rh.ferias", "crm.leads"]
}
```

Query adicional após carregar módulos:
```sql
SELECT fc.key
  FROM saas.feature_catalog fc
  LEFT JOIN sistema_configuracao.tenant_feature_flags tf
         ON tf.tenant_id = $1 AND tf.codigo = fc.key
  JOIN saas.tenant_modules tm
    ON tm.tenant_id = $1 AND tm.modulo = fc.modulo AND tm.ativo = TRUE
 WHERE COALESCE(tf.activo, fc.ativo_por_defeito) = TRUE
```

**Ficheiro novo: `backend/internal/modules/features/handlers/`**
```
GET  /api/features/catalog                     → lista por módulo (tenant)
GET  /api/features/tenant                      → features activas
POST /api/superadmin/features/{tenantId}/{key} → superadmin define
POST /api/admin/features/{key}                 → tenant admin configura (se configuravel)
```

**`permissoes.go` — `ObterAcessoUtilizador`**
- Resposta passa a incluir `"features": ["rh.ferias", "crm.leads", ...]`

### 2.4 Alterações PHP

**`AdminSession.php`**
```php
// Em syncModulos() — já existente:
$_SESSION['nexora_features'] = $resp['body']['features'] ?? [];

// Novo método:
public function canFeature(string $feature): bool {
    if ($this->isSuperAdmin()) return true;
    return in_array($feature, $_SESSION['nexora_features'] ?? [], true);
}
```

**`AdminPageGuard.php`**
```php
public function requireFeature(string $feature): void {
    $this->requireAuthenticated();
    if (!$this->session->canFeature($feature)) {
        $this->redirect403('Funcionalidade não disponível no seu plano.');
    }
}
```

**Uso nos templates:**
```php
<?php if ($app->guard->canFeature('rh.avaliacoes')): ?>
    <!-- bloco de avaliações de desempenho -->
<?php endif; ?>
```

---

## Fase 3 — Planos → Módulos (Entitlement)

**Duração estimada:** 3 dias  
**Migration:** `060_plan_modules.sql`

### 3.1 Tabela

```sql
CREATE TABLE saas.plan_modules (
  plan_id BIGINT      NOT NULL REFERENCES saas.plans(id) ON DELETE CASCADE,
  modulo  VARCHAR(60) NOT NULL REFERENCES saas.module_catalog(key) ON DELETE CASCADE,
  PRIMARY KEY (plan_id, modulo)
);
```

### 3.2 Dados por plano

**Básico (id=1):** clientes, vendas, faturacao, stock, financeiro, notificacoes

**Profissional (id=2):** tudo do Básico + crm, compras, recursos-humanos, pedido-ferias, tesouraria, impostos, recrutamento

**Empresarial (id=3):** todos os módulos do catálogo

### 3.3 Alterações Go

**`ActualizarModuloTenant`** — validação adicional ao activar:
```
1. Obter plano_id do tenant via saas.tenant_subscriptions
2. Verificar se modulo ∈ saas.plan_modules WHERE plan_id = plano_id
3. Se não: erro 402 { error: "Módulo não incluído no plano Básico" }
4. Se sim: continuar com validação de deps e activação
```

**Na criação de novo tenant** (handler existente):
```
Após INSERT em saas.tenants:
  → INSERT INTO saas.tenant_modules (tenant_id, modulo, ativo)
    SELECT $tenantId, modulo, TRUE FROM saas.plan_modules WHERE plan_id = $planId
```

**Endpoints:**
```
GET /api/superadmin/plans/{id}/modules    → módulos do plano
PUT /api/superadmin/plans/{id}/modules    → actualizar módulos do plano
```

---

## Fase 4 — Fluxos de Aprovação

**Duração estimada:** 2+ semanas  
**Migration:** `061_approval_flows.sql`  
**Pré-requisito:** definição das regras de negócio por módulo

### 4.1 Tabelas

```sql
-- Definição de fluxo por tenant + feature
CREATE TABLE saas.approval_flows (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id  BIGINT       NOT NULL REFERENCES saas.tenants(id),
  feature    VARCHAR(120) NOT NULL,              -- 'compras.requisicoes'
  nome       VARCHAR(150) NOT NULL,
  condicao   JSONB        NOT NULL DEFAULT '{}', -- {"valor_acima": 50000}
  niveis     JSONB        NOT NULL,
  -- [{"nivel": 1, "cargo_id": 5, "prazo_horas": 24},
  --  {"nivel": 2, "cargo_id": 3, "prazo_horas": 48}]
  ativo      BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, feature, nome)
);

-- Pedidos de aprovação em curso
CREATE TABLE saas.approval_requests (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id    BIGINT      NOT NULL REFERENCES saas.tenants(id),
  flow_id      BIGINT      NOT NULL REFERENCES saas.approval_flows(id),
  entidade     VARCHAR(60) NOT NULL,   -- 'compras.purchase_requests'
  entidade_id  BIGINT      NOT NULL,
  nivel_atual  INT         NOT NULL DEFAULT 1,
  estado       VARCHAR(20) NOT NULL DEFAULT 'pendente',
  -- 'pendente' | 'aprovado' | 'rejeitado' | 'cancelado'
  criado_por   BIGINT      NOT NULL REFERENCES auth.users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Histórico de decisões por nível
CREATE TABLE saas.approval_decisions (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  request_id   BIGINT      NOT NULL REFERENCES saas.approval_requests(id),
  nivel        INT         NOT NULL,
  decisao      VARCHAR(20) NOT NULL,  -- 'aprovado' | 'rejeitado'
  aprovado_por BIGINT      NOT NULL REFERENCES auth.users(id),
  comentario   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_approval_requests_tenant  ON saas.approval_requests(tenant_id, estado);
CREATE INDEX idx_approval_requests_entidade ON saas.approval_requests(entidade, entidade_id);
```

### 4.2 Lógica de aprovação

```
Pedido criado (ex: requisição de compra acima de 50.000 MT)
  → verificar se existe approval_flow para feature + condicao
  → se sim: criar approval_request (estado: pendente, nivel: 1)
  → notificar utilizadores do cargo do nível 1

Aprovador do nível 1 aprova
  → INSERT approval_decisions (nivel 1, aprovado)
  → se existir nível 2: nivel_atual = 2, notificar cargo nível 2
  → se último nível: estado = 'aprovado', desbloquear entidade

Aprovador rejeita em qualquer nível
  → estado = 'rejeitado', notificar criador
```

---

## Sequência de Entrega

```
Semana 1 ─── Fase 1: Catálogo + Dependências
  Dia 1-2: Migration 058 + seed (módulos + grafo)
  Dia 3:   Go: ListarModulosDisponiveis lê DB
  Dia 4:   Go: module_deps.go + ActualizarModuloTenant com cascade/bloqueio
  Dia 5:   PHP UI: grupos por categoria + badges deps + modais

Semana 2 ─── Fase 2: Feature Flags
  Dia 1-2: Migration 059 + seed feature_catalog
  Dia 3-4: Go: handlers features + LoadUserAccess estendido
  Dia 5:   PHP: canFeature() + guards nos templates

Semana 3 ─── Fase 3: Planos → Módulos
  Dia 1:   Migration 060 + seed plan_modules
  Dia 2-3: Go: validação entitlement + auto-activação no registo
  Dia 4-5: UI superadmin: gestão de módulos por plano

Semana 4+ ── Fase 4: Aprovações
  Semana de design das regras por módulo antes de implementar
  Implementação: 2+ semanas
```

---

## Ficheiros a Criar / Alterar

### Fase 1

| Tipo | Ficheiro |
|---|---|
| 🆕 Migration | `backend/migrations/058_module_catalog.sql` |
| 🆕 Go | `backend/internal/modules/superadmin/handlers/module_deps.go` |
| ✏️ Go | `backend/internal/modules/superadmin/handlers/modules.go` |
| ✏️ PHP | `frontend/src/View/templates/pages/superadmin_modules.php` |

### Fase 2

| Tipo | Ficheiro |
|---|---|
| 🆕 Migration | `backend/migrations/059_feature_catalog.sql` |
| 🆕 Go | `backend/internal/modules/features/handlers/features.go` |
| ✏️ Go | `backend/internal/modules/auth/models/rbac.go` |
| ✏️ Go | `backend/internal/modules/auth/handlers/permissoes.go` |
| ✏️ Go | `backend/internal/router/router.go` |
| ✏️ PHP | `frontend/src/Infrastructure/Auth/AdminSession.php` |
| ✏️ PHP | `frontend/src/Routing/AdminPageGuard.php` |

### Fase 3

| Tipo | Ficheiro |
|---|---|
| 🆕 Migration | `backend/migrations/060_plan_modules.sql` |
| ✏️ Go | `backend/internal/modules/superadmin/handlers/modules.go` |
| ✏️ Go | `backend/internal/modules/superadmin/handlers/tenants.go` |

### Fase 4

| Tipo | Ficheiro |
|---|---|
| 🆕 Migration | `backend/migrations/061_approval_flows.sql` |
| 🆕 Go | `backend/internal/modules/approvals/` (package novo) |
| 🆕 PHP | `frontend/src/View/templates/pages/aprovacoes.php` |

---

## Riscos e Notas Técnicas

| Risco | Mitigação |
|---|---|
| Ciclos no grafo de dependências | Função `validarDAG()` antes de INSERT em `module_dependencies` |
| `autorizacao.*` schema legado (parallel RBAC) | Nunca usar — sempre `auth.permissoes_*` |
| Cache de 5 min para features | Features sincronizadas no mesmo ciclo que módulos (`syncModulos`) — sem delay adicional |
| Tenant sem plano associado | `ActualizarModuloTenant` trata `plan_id IS NULL` como "sem restrição" (superadmin override) |
| Migrações em prod com dados | Fases 1-3 são additive (novas tabelas) — zero risco de dados existentes |
