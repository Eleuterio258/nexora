# Análise de Dependências — Módulo de Gestão Escolar

> Referência: [modulo-gestao-escolar.md](modulo-gestao-escolar.md)
> Data: 2026-06-26
> Escopo: backend Go, base de dados PostgreSQL, frontend PHP, migrações SQL

---

## 1. Visão Geral

O módulo de Gestão Escolar é parte nativa do Nexora ERP. Esta análise mapeia todas as dependências directas e indirectas que o módulo tem com os restantes 29 módulos do ERP, tanto no código Go como na base de dados e no frontend PHP.

### Resumo executivo

| Módulo | Tipo de dependência | Estado | Criticidade |
| --- | --- | --- | --- |
| **Auth** | BD (FK), Middleware (RBAC, JWT) | Implementado | Crítica |
| **Tesouraria** | BD (cross-schema INSERT) | Implementado — opcional | Alta |
| **SaaS/Tenants** | BD (seeds por tenant) | Implementado | Alta |
| **Centros de Custo** | BD (referência sem FK) | Previsto | Média |
| **Financeiro** | BD (referência sem FK) | Previsto | Alta |
| **Contabilidade** | BD (referência sem FK) | Previsto | Alta |
| **Notificações** | API (chamada de serviço) | Previsto | Média |
| **Clientes/CRM** | Manual | Manual | Baixa |
| **Recursos Humanos** | Nenhuma | Independente | Nula |
| **Auditoria** | Middleware | Implementado | Crítica |

---

## 2. Mapa de Dependências

```
gestao-escolar
│
├── [CRÍTICA - IMPLEMENTADO] ──────────── auth
│   ├── auth.users          (FK em 16 tabelas escolar: user_id, created_by, etc.)
│   ├── auth.permissoes_tipo (11 permissões RBAC inseridas na migration 066)
│   └── JWT middleware       (mw.GetUser → u.TenantID, u.ID em todos os handlers)
│
├── [CRÍTICA - IMPLEMENTADO] ──────────── auditoria
│   └── mw.AuditModule(db, "/api/escolar", "gestao-escolar")
│       aplicado a TODAS as rotas /api/escolar no router
│
├── [ALTA - IMPLEMENTADO OPCIONAL] ───── tesouraria
│   ├── tesouraria.movimentos_financeiros  (INSERT ao registar pagamento)
│   │   ⚠ Tabela existe no snapshot da BD mas NÃO na migration 044
│   │   ⚠ Migration 067 adiciona 'escolar' ao CHECK constraint com IF EXISTS
│   └── tesouraria.contas_bancarias        (FK não enforced em school_financial_config)
│       ⚠ Migration 044 cria bank_accounts (nome diferente)
│
├── [ALTA - IMPLEMENTADO] ─────────────── saas/tenants
│   └── saas.tenants   (migration 062 faz INSERT ... FROM saas.tenants para seeds)
│
├── [ALTA - PREVISTO] ──────────────────── financeiro
│   └── school_financial_config.conta_receita_id  (INT sem FK constraint)
│       Flag: criar_movimento_financeiro = FALSE (não implementado)
│
├── [ALTA - PREVISTO] ──────────────────── contabilidade
│   └── Lançamentos de receitas de propinas  (sem código implementado)
│
├── [MÉDIA - PREVISTO] ─────────────────── centros-custo
│   └── school_financial_config.centro_custo_id  (INT sem FK constraint)
│       Tabela real: centros_custo.cost_centers  (ver migration 069)
│
├── [MÉDIA - PREVISTO] ─────────────────── notificações
│   └── Alertas automáticos de faltas, notas, comunicados
│       (sem chamadas a /api/notificacoes no código actual)
│
├── [BAIXA - MANUAL] ───────────────────── gestao-clientes
│   └── Alunos/encarregados como entidades CRM  (sem sincronização automática)
│
└── [NULA - INDEPENDENTE] ──────────────── recursos-humanos
    └── Professores geridos em gestao_escolar.school_teachers
        (nunca sincronizados com rh.funcionarios)
```

---

## 3. Dependências Detalhadas

### 3.1 AUTH — Dependência Crítica

**Tipo:** Foreign Keys na BD + Middleware RBAC + JWT

**Tabelas de `auth` referenciadas por `gestao_escolar`:**

| Tabela gestao_escolar | Campo | Referência | ON DELETE |
| --- | --- | --- | --- |
| school_teachers | user_id | auth.users(id) | SET NULL |
| school_students | user_id | auth.users(id) | SET NULL |
| school_enrollments | created_by | auth.users(id) | SET NULL |
| school_attendance | created_by | auth.users(id) | SET NULL |
| school_payments | created_by | auth.users(id) | SET NULL |
| school_calendar_events | created_by | auth.users(id) | SET NULL |
| school_student_incidents | reported_by | auth.users(id) | RESTRICT |
| school_student_sanctions | aplicado_por | auth.users(id) | RESTRICT |
| school_student_merits | atribuido_por | auth.users(id) | SET NULL |
| school_fee_generations | gerado_por | auth.users(id) | SET NULL |
| school_student_fee_discounts | aprovado_por | auth.users(id) | SET NULL |
| school_years | created_by | auth.users(id) | SET NULL |
| school_terms | created_by | auth.users(id) | SET NULL |
| school_subjects | created_by | auth.users(id) | SET NULL |
| school_fee_plans | created_by | auth.users(id) | SET NULL |
| school_grade_items | created_by | auth.users(id) | SET NULL |
| school_grades | lancado_por | auth.users(id) | SET NULL |

**Permissões RBAC (migration 066):**

| Permissão | Rotas | Perfis |
| --- | --- | --- |
| `ver_escolar` | GET tudo | tenant_admin, professor, funcionario |
| `gerir_academico` | POST/PUT/DELETE anos, turmas, disciplinas, estrutura | tenant_admin |
| `gerir_professores` | POST/PUT/DELETE /teachers | tenant_admin |
| `gerir_alunos` | CRUD /students, /enrollments | tenant_admin, funcionario |
| `gerir_frequencia` | POST/PUT /attendance | tenant_admin, professor, funcionario |
| `gerir_avaliacoes` | CRUD /grades, /grade-items | tenant_admin, professor |
| `gerir_financeiro` | CRUD /fee-plans, /payments | tenant_admin, funcionario |
| `gerir_biblioteca` | CRUD /library/* | tenant_admin |
| `gerir_comunicacao` | CRUD /messages | tenant_admin |
| `gerir_horarios` | CRUD /timetables, /calendar* | tenant_admin |
| `gerir_ocorrencias` | CRUD /incidents, /sanctions | tenant_admin |

**Uso no código:**
- `mw.GetUser(r)` em todos os handlers — fornece `u.TenantID` e `u.ID`
- `mw.RequirePermission(db, "gestao-escolar", "permissao")` — 11 grupos no router
- `mw.RequireAuth(cfg.JWTSecret, db)` — aplicado a toda a rota `/api/escolar`

**Ficheiros críticos:**
- `backend/internal/router/router.go:728-890`
- `backend/migrations/062_gestao_escolar_foundation.sql:186,231,330,358-363`
- `backend/migrations/064_gestao_escolar_ocorrencias.sql:45,66,88`
- `backend/migrations/065_gestao_escolar_configuracao_avancada.sql:81,100`
- `backend/migrations/066_permissoes_gestao_escolar.sql`

**Risco se indisponível:**
- Nenhum acesso ao módulo (bloqueio no middleware JWT)
- FKs com RESTRICT bloqueiam DELETE de utilizadores com ocorrências/sanções
- Seeds de permissões falham silenciosamente (migration 066 tem IF EXISTS)

---

### 3.2 TESOURARIA — Dependência Opcional Implementada

**Tipo:** Cross-schema INSERT + referência de FK não enforced

**Fluxo implementado:**
1. `services/fee.go:RegisterPayment()` regista pagamento em `school_payments`
2. Lê `school_financial_config.criar_movimento_tesouraria` (padrão: FALSE)
3. Se TRUE → chama `repositories/fee.go:CreateTreasuryMovement()`
4. Insere em `tesouraria.movimentos_financeiros`

**Query crítica** (`repositories/fee.go:169-177`):
```sql
INSERT INTO tesouraria.movimentos_financeiros
(tenant_id, origem_tipo, origem_id, conta_bancaria_id,
 tipo, valor, referencia, descricao, data_movimento)
VALUES ($1,'escolar',NULL,$2,'recebimento',$3,$4,$5,$6)
```

**⚠ PROBLEMA CRÍTICO DE SCHEMA:**

| Fonte | Tabela | Conta bancária |
| --- | --- | --- |
| Snapshot BD (`nexora_erp_20260623.sql`) | `tesouraria.movimentos_financeiros` | `tesouraria.contas_bancarias` |
| Migration 044 | `tesouraria.movements` | `tesouraria.bank_accounts` |
| fee.go (código) | `tesouraria.movimentos_financeiros` ✓ | `tesouraria.contas_bancarias` ← referencia (sem FK) |

O módulo escolar foi escrito contra o schema do **snapshot** (tabelas antigas), não contra as tabelas criadas pela **migration 044** (nomes novos em inglês). Se a BD for recriada apenas com as migrações, o INSERT falhará porque `tesouraria.movimentos_financeiros` não existe.

**Migration 067** adiciona `'escolar'` ao CHECK constraint de `origem_tipo` em `movimentos_financeiros` com `IF EXISTS` — se a tabela não existir na BD, a migration passa silenciosamente e o INSERT falhará com violação de constraint.

**Ficheiros críticos:**
- `backend/internal/modules/gestao-escolar/repositories/fee.go:169-177` — INSERT
- `backend/internal/modules/gestao-escolar/repositories/fee.go:179-196` — GetFinancialConfig
- `backend/internal/modules/gestao-escolar/services/fee.go:146-188` — RegisterPayment
- `backend/migrations/067_gestao_escolar_financeiro.sql:10-23` — ALTER TABLE (IF EXISTS)
- `docs/nexora ERP/tesouraria/database-tesouraria.sql` — definição original da tabela

**Risco:**
- **Alto**: Se BD recriada com migrações, integração Tesouraria falha silenciosamente
- **Médio**: conta_bancaria_id sem FK enforced pode apontar para IDs inválidos

**Acção recomendada:**
- Criar migration que garante existência de `tesouraria.movimentos_financeiros` (ou adaptar fee.go para usar `tesouraria.movements`)
- Adicionar FK constraint: `ALTER TABLE school_financial_config ADD CONSTRAINT fk_conta_bancaria FOREIGN KEY (conta_bancaria_id) REFERENCES tesouraria.contas_bancarias(id) ON DELETE SET NULL`

---

### 3.3 SAAS/TENANTS — Dependência de Setup

**Tipo:** Seeds condicionais por tenant

**Uso:** Migration 062 insere dados padrão (níveis de ensino, tipos de avaliação, slots de tempo) para cada tenant existente:

```sql
-- Exemplo da migration 062:
INSERT INTO school_levels (tenant_id, codigo, nome, ...)
SELECT id, 'EP', 'Ensino Primário', ...
FROM saas.tenants
WHERE ...
ON CONFLICT DO NOTHING;
```

**Risco:**
- Se `saas.tenants` não existir na migration 062, os seeds não são inseridos
- Novos tenants criados após a migration 062 não recebem os dados padrão (necessário seeder separado)

---

### 3.4 FINANCEIRO — Dependência Prevista (Não Implementada)

**Campo:** `school_financial_config.conta_receita_id BIGINT` (sem FK constraint)

**Flag:** `criar_movimento_financeiro BOOLEAN DEFAULT FALSE`

**O que deveria fazer (não implementado):**
- Ao registar pagamento de propina, criar movimento/factura no módulo Financeiro
- Similar ao que já existe para Tesouraria

**Ponto de integração futuro:**
- `services/fee.go:RegisterPayment()` — após linha 185 (bloco Tesouraria)
- Novo método `repositories/fee.go:CreateFinancialMovement()`
- Query alvo: `INSERT INTO financeiro.??? (tenant_id, origem_tipo, ...)`

**Tabela destino a confirmar:**
- Verificar em `backend/migrations/033_*.sql` ou `035_*.sql` qual tabela do módulo Financeiro recebe movimentos de receita

**Risco actual:**
- Propinas pagas não entram no módulo Financeiro
- Reconciliação entre Escolar e Financeiro é manual

---

### 3.5 CENTROS DE CUSTO — Dependência Prevista (Não Implementada)

**Campo:** `school_financial_config.centro_custo_id BIGINT` (sem FK constraint)

**Tabela real:** `centros_custo.cost_centers` (confirmado em migration 069, linha 10)

**Comparação com RH (já implementado):**
```sql
-- migration 069_rh_folha_integracao_fase1.sql:10
ADD COLUMN IF NOT EXISTS centro_custo_id BIGINT
    REFERENCES centros_custo.cost_centers(id)
```

**Acção recomendada:**
- Adicionar FK constraint: `ALTER TABLE school_financial_config ADD CONSTRAINT fk_centro_custo FOREIGN KEY (centro_custo_id) REFERENCES centros_custo.cost_centers(id) ON DELETE SET NULL`
- Usar o centro_custo_id nos lançamentos financeiros/contabilísticos quando implementados

---

### 3.6 NOTIFICAÇÕES — Dependência Prevista (Não Implementada)

**Casos de uso previstos:**
- Alerta de faltas injustificadas (ao lançar frequência)
- Notificação de notas publicadas (ao publicar avaliação)
- Publicação de comunicados (ao publicar mensagem)

**Pontos de integração futuros:**
| Handler | Evento | Ponto de inserção |
| --- | --- | --- |
| `academico.go:LancarFrequencia` | Faltas registadas | Após INSERT bem-sucedido |
| `grades.go:PublicarAvaliacao` | Notas publicadas | Após `gradeService().PublishItem()` |
| `comunicacao.go:PublicarMensagemEscolar` | Comunicado publicado | Após UPDATE status='publicado' |
| `turmas_matriculas.go:CriarMatriculaV2` | Matrícula criada | Após `enrollmentService().Create()` |

**Endpoint destino:** `POST /api/notificacoes` ou chamada directa ao serviço

---

### 3.7 CLIENTES/CRM — Integração Manual

**Estado:** Sem código de integração. Alunos e encarregados são entidades independentes em `gestao_escolar.school_students` e `gestao_escolar.school_guardians`.

**Campo potencial para ligação futura:**
- `school_students.client_id BIGINT` (não existe actualmente)
- `school_guardians.client_id BIGINT` (não existe actualmente)

---

### 3.8 RECURSOS HUMANOS — Independente (Intencional)

**Razão:** Professores escolares são específicos de cada escola e não estão no módulo RH corporativo. A entidade `gestao_escolar.school_teachers` é autónoma.

**Campo `user_id`** em `school_teachers` pode ligar o professor a um utilizador do ERP (via `auth.users`) mas não a um `rh.funcionarios`.

---

## 4. Dependências de Fora para Dentro (quem depende do Escolar)

### 4.1 Router

O único ficheiro Go fora do módulo que referencia diretamente o módulo escolar é o router:

```go
// backend/internal/router/router.go:24
escolarH "nexora/internal/modules/gestao-escolar/handlers"

// backend/internal/router/router.go:54
escolar := escolarH.New(db, cfg)
```

**Nenhum outro módulo Go importa** `nexora/internal/modules/gestao-escolar`.

### 4.2 Tesouraria — Impacto da Migration 067

Migration 067 modifica a tabela `tesouraria.movimentos_financeiros` para aceitar `'escolar'` como valor de `origem_tipo`. Isto impacta:
- Qualquer query que leia `movimentos_financeiros.origem_tipo` no módulo Tesouraria
- Relatórios que agrupam por `origem_tipo`

### 4.3 Frontend PHP

**35 páginas PHP** dedicadas ao módulo escolar (todas com prefixo `escolar_*.php`).

**Verificar dependências cruzadas no frontend:**
- Páginas de propinas (`escolar_cobrancas.php`, `escolar_pagamentos.php`) provavelmente precisam de carregar lista de contas bancárias do módulo Tesouraria para configurar `conta_bancaria_id`
- Páginas de configuração precisam de carregar centros de custo do módulo Centros-Custo
- Nenhuma destas dependências foi verificada directamente — **recomenda-se auditoria do SchoolService.php**

---

## 5. Análise de Risco das Migrações

### Ordem de execução crítica

| Migração | Depende de | Risco se fora de ordem |
| --- | --- | --- |
| `062_gestao_escolar_foundation.sql` | auth.users (para FKs), saas.tenants (para seeds) | FKs inválidas, seeds não inseridas |
| `063_gestao_escolar_horarios_calendario.sql` | 062 (school_classes, school_subjects) | FK violations na criação |
| `064_gestao_escolar_ocorrencias.sql` | 062 (school_students, school_classes) | FK violations |
| `065_gestao_escolar_configuracao_avancada.sql` | 062 (school_students, school_enrollments) | FK violations |
| `066_permissoes_gestao_escolar.sql` | auth.permissoes_tipo | Seeds falham silenciosamente |
| `067_gestao_escolar_financeiro.sql` | tesouraria.movimentos_financeiros | IF EXISTS → silencioso se tabela inexiste |

**⚠ Risco Principal:** Migration 067 usa `IF EXISTS` para verificar `tesouraria.movimentos_financeiros`. Se a BD for criada do zero apenas com as migrações (sem o snapshot), esta tabela não existirá (migration 044 cria `tesouraria.movements`) e o ALTER TABLE não será executado. Quando o módulo escolar registar um pagamento com `criar_movimento_tesouraria=TRUE`, o INSERT em `tesouraria.movimentos_financeiros` falhará com "relation does not exist".

---

## 6. Infra-estrutura Partilhada

### 6.1 Middleware (`nexora/internal/middleware`)

| Middleware | Uso no módulo escolar |
| --- | --- |
| `mw.RequireAuth` | Validação JWT — aplicado a `/api/escolar` |
| `mw.GetUser` | Extrai TenantID e UserID do JWT — usado em TODOS os handlers |
| `mw.RequirePermission` | RBAC — 11 grupos de permissões |
| `mw.AuditModule` | Auditoria de todas as acções — aplicado a `/api/escolar` |

### 6.2 Configuração (`nexora/config`)

Campos de `config.Config` usados pelo módulo escolar (injectados em `handlers.New(db, cfg)`):

| Campo | Uso |
| --- | --- |
| `cfg.JWTSecret` | Validação do token JWT via `mw.RequireAuth` |
| `*pgxpool.Pool` | Pool de ligações à BD — partilhado com todos os módulos |

---

## 7. Gaps por Prioridade

### Prioridade Alta — Bloqueador

**7.1 Inconsistência de schema Tesouraria**
- **Problema:** `tesouraria.movimentos_financeiros` referenciado no código mas criado pelo snapshot, não pelas migrações Go
- **Risco:** BD recriada do zero → integração falha em runtime
- **Acção:** Criar migration que assegura existência da tabela OU adaptar fee.go para usar `tesouraria.movements`

### Prioridade Alta — Funcionalidade

**7.2 Integração com Financeiro**
- **Problema:** `criar_movimento_financeiro=TRUE` não faz nada
- **Acção:** Implementar `CreateFinancialMovement()` em `repositories/fee.go` e chamar em `services/fee.go:RegisterPayment()`

**7.3 Integração com Contabilidade**
- **Problema:** Nenhum lançamento contabilístico ao registar propinas
- **Acção:** Implementar após definir tabela destino no módulo Contabilidade

### Prioridade Média — Consistência de Dados

**7.4 FK Constraint — Centros de Custo**
- **Problema:** `school_financial_config.centro_custo_id` sem FK enforced
- **Acção:** `ALTER TABLE gestao_escolar.school_financial_config ADD CONSTRAINT fk_centro_custo FOREIGN KEY (centro_custo_id) REFERENCES centros_custo.cost_centers(id) ON DELETE SET NULL`

**7.5 FK Constraint — Conta Bancária**
- **Problema:** `school_financial_config.conta_bancaria_id` sem FK enforced (e nome de tabela inconsistente entre snapshot e migration)
- **Acção:** Resolver primeiro o problema 7.1, depois adicionar FK

### Prioridade Média — Experiência de Utilizador

**7.6 Notificações Automáticas**
- **Problema:** Sem alertas para encarregados sobre faltas, notas, ocorrências
- **Acção:** Integrar com módulo Notificações nos handlers de frequência, avaliações e comunicados

### Prioridade Baixa — Dados Duplicados

**7.7 Sincronização com Clientes/CRM**
- **Problema:** Alunos e encarregados não estão vinculados ao módulo Clientes
- **Acção:** Decisão de produto — sincronização automática vs. manual vs. não necessária

---

## 8. Ficheiros Críticos — Referência Rápida

| Ficheiro | Dependência | Linha |
| --- | --- | --- |
| `backend/internal/router/router.go` | Auth (RBAC), import do módulo | 24, 54, 728-890 |
| `backend/internal/modules/gestao-escolar/repositories/fee.go` | Tesouraria (INSERT) | 169-177 |
| `backend/internal/modules/gestao-escolar/repositories/fee.go` | Financeiro (config lida) | 179-196 |
| `backend/internal/modules/gestao-escolar/services/fee.go` | Tesouraria (lógica condicional) | 146-188 |
| `backend/migrations/062_gestao_escolar_foundation.sql` | Auth (FKs), SaaS (seeds) | 186, 231, 330, 358-363, 386-540 |
| `backend/migrations/064_gestao_escolar_ocorrencias.sql` | Auth (FKs) | 45, 66, 88 |
| `backend/migrations/065_gestao_escolar_configuracao_avancada.sql` | Financeiro, Centros-Custo (sem FK) | 110-112 |
| `backend/migrations/066_permissoes_gestao_escolar.sql` | Auth (permissoes_tipo) | Todos |
| `backend/migrations/067_gestao_escolar_financeiro.sql` | Tesouraria (ALTER TABLE IF EXISTS) | 10-23 |
| `docs/nexora ERP/tesouraria/database-tesouraria.sql` | Define movimentos_financeiros original | 24-38 |
