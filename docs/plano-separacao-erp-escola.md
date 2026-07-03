# Plano de separação ERP vs. Painel Escolar

## Visão geral

Este documento descreve as fases para implementar uma separação clara entre:

- **Contas ERP**: acedem apenas a `/nexora/*` (módulos empresariais).
- **Contas Escola**: acedem apenas a `/escola/*` (módulos escolares), sem prefixo `/nexora`.
- **Contas ERP + Escola**: acedem a ambos os painéis.

A separação será feita através de uma flag explícita `escopo` no utilizador (`erp`, `escola`, `ambos`), combinada com o RBAC actual (cargos e permissões).

---

## Estado actual

- O Painel Escolar já existe em `/escola/*` com layout dedicado (`escola_top.php`).
- A sidebar do ERP já não mostra o módulo "Gestão Escolar".
- O dashboard do ERP já não mostra cards/links para a escola.
- O redirecionamento para `/escola` é feito apenas quando o utilizador tem **apenas** `gestao-escolar` como módulo de negócio.
- **Não existe flag explícita** de "apenas escolar" vs "ERP + escolar".
- **Existe um desalinhamento crítico** entre as permissões escolares seedadas nas migrations e as ações exigidas pelo `router.go`, causando 403 para utilizadores não-superadmin.

---

## Fase 1 — Corrigir permissões escolares

### Objetivo
Alinhar as permissões do módulo `gestao-escolar` entre o `router.go` e as migrations.

### Problemas
1. A migration `066_permissoes_gestao_escolar.sql` usa nomes de ações diferentes dos exigidos pelo router:
   - `ver_escolar` → deveria ser `ver`
   - `gerir_academico` / `gerir_professores` → deveria ser `gerir_turmas`
   - `gerir_frequencia` → deveria ser `gerir_presencas`
   - `gerir_avaliacoes` → deveria ser `lancar_notas`
   - `gerir_financeiro` → deveria ser `gerir_propinas`
2. Faltam ações em `auth.permissoes_tipo`: `relatorios`, `gerir_matriculas`, `gerir_calendario`, `portal_aluno`.
3. O tipo `professor` foi removido do CHECK de `auth.users.tipo` na migration `080`.
4. Endpoint órfão: `GET /api/escolar/relatorios/aging` não exige permissão.
5. Ex-`tenant_admin` ficaram como `funcionario` sem cargo.

### Ações
1. Reescrever `backend/migrations/066_permissoes_gestao_escolar.sql` com os nomes correctos.
2. Criar migration de alinhamento idempotente para limpar e re-inserir permissões escolares.
3. Proteger o endpoint `/api/escolar/relatorios/aging` no `router.go`.
4. Criar migration para atribuir cargo `Administrador` a utilizadores `funcionario` sem cargo.

### Resultado
Utilizadores não-superadmin com permissões escolares conseguem aceder a `/escola/*` sem 403.

### Estado
✅ Concluída em `2026-06-29`.
- `066_permissoes_gestao_escolar.sql` reescrita para remover tipos/ações inválidos.
- `086_permissoes_escolares_alinhamento.sql` criada para limpar e re-inserir permissões correctas nos cargos padrão.
- `087_funcionarios_sem_cargo_administrador.sql` criada para atribuir cargo `Administrador` a ex-`tenant_admin` sem cargo.
- Endpoint `GET /api/escolar/relatorios/aging` protegido com `ver` ou `relatorios`.

---

## Fase 2 — Adicionar flag `escopo` ao utilizador

### Objetivo
Introduzir uma flag explícita que define se o utilizador acede só ao ERP, só à Escola, ou a ambos.

### Ações
1. Criar migration PostgreSQL:
   ```sql
   ALTER TABLE auth.users ADD COLUMN escopo VARCHAR(20) NOT NULL DEFAULT 'erp';
   ALTER TABLE auth.users ADD CONSTRAINT chk_users_escopo CHECK (escopo IN ('erp', 'escola', 'ambos'));
   ```
2. Atualizar `backend/internal/modules/auth/models/rbac.go` para incluir `Escopo` em `UserAccess`.
3. Atualizar `backend/internal/modules/auth/handlers/auth.go` para devolver `escopo` no login/refresh/me.
4. Incluir `escopo` nas claims do JWT.
5. Atualizar seeds/cargos padrão se necessário.

### Resultado
O backend conhece e expõe o escopo do utilizador em tokens e respostas.

### Estado
✅ Concluída em `2026-06-29`.
- `088_users_escopo.sql` criada para adicionar `auth.users.escopo` (default `erp`, CHECK `erp|escola|ambos`).
- `UserAccess` e `LoadUserAccess` em `rbac.go` passaram a carregar `Escopo`.
- JWT passou a incluir claim `escopo` (função `signAccess`).
- `AuthUser` e middlewares `RequireAuth`/`RequireJWT` extraem `escopo` do token.
- Login, refresh, `/me` e `GatewayValidate` devolvem/exportam `escopo`.
- CRUD de utilizadores (`ListarUtilizadores`, `CriarUtilizador`, `ObterUtilizador`, `ActualizarUtilizador`) suporta `escopo`.

---

## Fase 3 — Reforçar separação no backend

### Objetivo
Garantir que o backend rejeite acessos fora do escopo do utilizador.

### Ações
1. Criar middleware `RequireEscopo(...)` em `backend/internal/middleware/auth.go`.
2. Aplicar middlewares:
   - Rotas `/api/escolar/*` → `escopo IN ('escola', 'ambos')`.
   - Rotas ERP (`/api/faturacao/*`, `/api/rh/*`, etc.) → `escopo IN ('erp', 'ambos')`.
3. Ajustar `LoadUserAccess` para filtrar módulos pelo escopo:
   - Se `escopo = 'escola'`, remover permissões de módulos ERP.
4. Atualizar handlers de utilizadores para permitir definir `escopo` no create/update.
5. Garantir que superadmin bypassa todas as restrições de escopo.

### Resultado
Backend impede que um user "apenas escola" aceda a endpoints ERP, e vice-versa.

### Estado
✅ Concluída em `2026-06-29`.
- `RequireEscopo(...)` criado em `backend/internal/middleware/auth.go`.
- `RequireAuth` e `RequireJWT` passaram a rejeitar automaticamente pedidos fora do escopo do utilizador com base no path:
  - `/api/escolar/*` requer `escola` ou `ambos`;
  - `/api/*` (ERP) requer `erp` ou `ambos`;
  - `/api/auth/*` e `/api/portal/*` mantêm-se sem restrição de escopo.
- `LoadUserAccess` filtra permissões: contas `escola` só mantêm o módulo `gestao-escolar`.
- Superadmin bypassa todas as restrições de escopo.
- CRUD de utilizadores já suporta `escopo` (Fase 2).

---

## Fase 4 — Ajustar frontend para respeitar escopo

### Objetivo
O frontend deve direccionar cada tipo de conta para o painel correcto.

### Ações
1. `frontend/src/Infrastructure/Auth/AdminSession.php`:
   - Guardar `escopo` na sessão.
   - Adicionar métodos: `escopo()`, `isErpOnly()`, `isSchoolOnly()`, `isBoth()`.
2. `frontend/index.php`:
   - `/escola/*`: permitir `escopo IN ('escola', 'ambos')` + `canModule('gestao-escolar')`.
   - `/nexora/*`: rejeitar `escopo = 'escola'` (redireccionar para `/escola`).
3. `frontend/src/Controller/Admin/AdminPageGuard.php`:
   - Adicionar `requireEscopo()` para views.
4. `frontend/src/View/templates/pages/dashboard.php`:
   - Se `escopo = 'escola'` → redireccionar para `/escola`.
   - Se `escopo = 'ambos'` → mostrar card "Painel da Escola".
   - Se `escopo = 'erp'` → dashboard normal.
5. `frontend/src/View/templates/layouts/top.php`:
   - Adicionar link "Painel Escolar" apenas quando `escopo = 'ambos'`.
6. `frontend/src/View/templates/layouts/escola_top.php`:
   - Mostrar "Painel ERP Geral" apenas quando `escopo = 'ambos'` (ou superadmin/empresa).

### Resultado
Cada conta é direccionada para o painel adequado após login.

### Estado
✅ Concluída em `2026-06-29`.
- `AdminSession` guarda `escopo` e expõe `escopo()`, `isErpOnly()`, `isSchoolOnly()`, `isBoth()`.
- `homeUrl()` redirecciona contas `escola` para `/escola`.
- `index.php`:
  - `/escola/*` só é acessível a `escola`/`ambos` com `gestao-escolar`;
  - `/nexora/*` rejeita contas `escola` puras (redirecciona para `/escola`).
- `AdminPageGuard.requireEscopo()` adicionado.
- `dashboard.php` redirecciona `escola` → `/escola` e mostra card "Painel da Escola" para `ambos`.
- `top.php` mostra link "Painel Escolar" para contas `ambos`.
- `escola_top.php` mostra "Painel ERP Geral" apenas para `ambos` ou superadmin.
- `AdminAuthController` aceita redireccionamentos internos para `/escola` e `/nexora`.

---

## Fase 5 — Testes e validação

### Objetivo
Garantir que a separação funciona e não quebrou o ERP.

### Ações
1. Criar 3 utilizadores de teste:
   - `utilizador_erp` com `escopo = 'erp'`.
   - `utilizador_escola` com `escopo = 'escola'`.
   - `utilizador_ambos` com `escopo = 'ambos'`.
2. Testar login e redireccionamentos:
   - `erp` → fica em `/nexora`, não acede `/escola`.
   - `escola` → redirecciona para `/escola`, não acede `/nexora`.
   - `ambos` → fica em `/nexora` com link para `/escola`.
3. Testar endpoints backend:
   - `escola` não consegue chamar `/api/faturacao/*`.
   - `erp` não consegue chamar `/api/escolar/*`.
   - `ambos` consegue ambos.
4. Verificar que superadmin continua com acesso total.
5. Garantir migration de rollback para a coluna `escopo`.

### Resultado
Sistema estável com separação clara ERP/Escola.

### Estado
✅ Concluída em `2026-06-29`.
- `089_seed_utilizadores_teste_escopo.sql` criada com 3 contas de teste (cargo Administrador):
  - `erp_teste@nexora.test` / `Teste1234!` → escopo `erp`;
  - `escola_teste@nexora.test` / `Teste1234!` → escopo `escola`;
  - `ambos_teste@nexora.test` / `Teste1234!` → escopo `ambos`.
- `090_rollback_users_escopo.down.sql` criada para remover `auth.users.escopo` se necessário (rollback manual).
- Resolvidos conflitos de numeração de migrações (035, 080, 081).
- Migrações convertidas para o formato `golang-migrate` (`YYYYMMDDHHMMSS_nome.{up,down}.sql`) em `backend/migrations/`.
- Script `backend/scripts/run_migrations.sh` usa o CLI `migrate` (nativo ou Docker) para aplicar migrações pendentes.
- `backend/scripts/seed_golang_migrate.sql` converte o histórico aplicado no formato do `migrate`.
- Testes unitários `backend/internal/middleware/auth_test.go` validam:
  - `RequireEscopo` permite/bloqueia escopos correctamente;
  - superadmin bypassa;
  - `escopoPermitidoParaPath` aplica regras por prefixo de path.
- `go test ./...` passa no backend.

### Matriz de validação manual recomendada
| Conta de teste | Login | `/nexora` | `/escola` | `/api/faturacao/*` | `/api/escolar/*` |
|---|---|---|---|---|---|
| `erp_teste@nexora.test` | `/nexora` | ✅ | ❌ 403 | ✅ | ❌ 403 |
| `escola_teste@nexora.test` | `/escola` | ❌ redirect `/escola` | ✅ | ❌ 403 | ✅ |
| `ambos_teste@nexora.test` | `/nexora` | ✅ | ✅ | ✅ | ✅ |
| superadmin | `/nexora/superadmin` | ✅ | ✅ | ✅ | ✅ |

---

## Comportamento esperado por tipo de conta

| Tipo de conta | Permissões | Acesso ERP (`/nexora/*`) | Acesso Escola (`/escola/*`) | Comportamento após login |
|---|---|---|---|---|
| **ERP puro** | módulos ERP | Sim | Não | Fica em `/nexora` |
| **ERP + Escola** | ERP + `gestao-escolar` | Sim | Sim | Fica em `/nexora`, com link para `/escola` |
| **Apenas Escola** | só `gestao-escolar` | Não | Sim | Redirecciona para `/escola` |

---

## Notas importantes

- A separação actual (sem flag `escopo`) é implícita e baseada apenas nas permissões. Este plano torna-a explícita e robusta.
- O acesso de professores deve continuar a ser gerido por cargos (`auth.cargos`), não pelo tipo `professor` (removido intencionalmente).
- Os portais do aluno e encarregado (`/portal/aluno/*`, `/portal/encarregado/*`) mantêm autenticação separada e não são afectados por este plano.
