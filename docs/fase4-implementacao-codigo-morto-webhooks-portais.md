# Fase 4 — Código Morto, Webhooks e Portais

> Data: 2026-07-27

## Resumo

Esta fase limpa handlers órfãos, torna o callback de pagamentos escolares
acessível a gateways externos e reforça as validações nos portais do professor
e do aluno. Adiciona ainda `RequireFeature` nos módulos que ainda não tinham
proteção por funcionalidade.

## Alterações realizadas

### 1. Handler órfão removido

- `backend/internal/modules/gestao-escolar/handlers/academico.go`
  - Removida `ListarAvaliacoes` (não era referenciada em `router.go`; o router
    usa `ListarAvaliacoesV2` em `grades.go`).

### 2. Webhook de pagamentos escolares

- `backend/internal/router/router.go`
  - A rota `POST /api/escolar/payments/callback` foi movida para fora do grupo
    autenticado `/api/escolar`.
  - Fica pública, com rate limit (`mw.RateLimit(60, time.Minute)`), para que o
    gateway externo possa chamá-la sem JWT.
  - Mantida a validação HMAC-SHA256 (`X-Signature`) já existente no handler.

### 3. Portal do professor — validação de atribuição

- `backend/internal/modules/gestao-escolar/handlers/portal_professor.go`
  - Nova helper `professorAtribuidoTurma` verifica se o professor é director de
    turma ou está atribuído de forma activa em `school_teacher_assignments`.
  - Aplicada em:
    - `ProfessorPortalTurma`
    - `ProfessorPortalTurmaAlunos`

### 4. Portal do aluno — respeito por `publico_alvo`

- `backend/internal/modules/gestao-escolar/handlers/portal_data.go`
  - `PortalEventos` passou a filtrar eventos por `publico_alvo`
    (`todos`, `alunos`, `turma`, `curso`).
  - `PortalAlunoMarcarPresencas` agora confirma que o aluno está matriculado
    activamente na turma antes de permitir marcar presenças.

- `backend/internal/modules/gestao-escolar/handlers/portal_mobile.go`
  - `PortalDashboardAluno` passou a obter também o `course_id` da turma do
    aluno e a filtrar os eventos por `publico_alvo`.

### 5. `RequireFeature` adicionado

Migration `backend/migrations/20260727130000_garantir_feature_catalog_fase4.up.sql`:

- Garante a existência dos módulos e funcionalidades referenciadas.
- Insere features com `ativo_por_defeito = true` para não bloquear tenants
  existentes.

Aplicações no `router.go`:

| Rota | Feature |
|---|---|
| `/api/stock` | `stock` |
| `/api/compras` | `compras` |
| `/api/faturacao` | `vendas.fatura_direta` |
| `/api/faturacao/quotes` | `vendas.orcamentos` |
| `/api/faturacao/orders` | `vendas.encomendas` |
| `/api/faturacao/credit-notes` | `vendas.devolucoes` |
| `/api/crm` | `crm.leads` |
| `/api/crm/oportunidades` | `crm.oportunidades` |
| `/api/crm/atividades` | `crm.atividades` |
| `/api/rh` | `rh.assiduidade` |
| `/api/contabilidade` | `contabilidade` |
| `/api/centros-custo` | `cont.centros_custo` |
| Grupo logística (`/api/delivery-*`) | `logistica` |

A feature `compras.aprovacoes` já existia no grupo `/api/aprovacoes/flows` e
foi mantida.

## Validação

```bash
cd backend && go build ./...
cd backend && go test ./...
cd backend && go vet ./...
```

Todos os comandos terminaram com sucesso.

## Notas

- A proteção por feature só bloqueia tenants onde a feature esteja explicitamente
  desactivada (`tenant_feature_flags`) ou cujo `ativo_por_defeito` no catálogo
  seja `false`. Como as features inseridas usam `ativo_por_defeito = true`, o
  comportamento dos tenants existentes não mudou.
- Handlers removidos/órfãos noutros módulos (`gestao-produtos`, `auditoria`,
  `seguranca`, `aprovacoes`) não foram encontrados nesta fase; o subagente de
  análise identificou apenas `ListarAvaliacoes` como órfão real.
