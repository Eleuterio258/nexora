# Análise: Granularidade de Permissões do POS

**Data:** 2026-08-12  
**Âmbito:** Módulo POS do Nexora ERP (`pos`, `backend/internal/modules/pos`)  
**Objetivo:** Definir permissões finas por persona, alinhadas com o modelo da Gestão Escolar e preparadas para os portais `/pos/operador`, `/pos/gerente`, `/pos/admin`.

---

## 1. Resumo executivo

Hoje o POS tem **pouca granularidade de permissões**:

- No código Go, apenas `pos:operar_pos` é referenciada explicitamente.
- Em `docs/CARGOS.md`, o cargo **Caixa** tem `pos:ver,criar,editar,relatorios`.
- Não há distinção entre operar caixa, gerir terminais, gerir catálogo, fechar sessão, cancelar vendas, aceder a relatórios, etc.

Comparando com a **Gestão Escolar**, que tem ações específicas como `gerir_turmas`, `gerir_alunos`, `lancar_notas`, `gerir_presencas`, `gerir_propinas`, `portal_aluno`, o POS precisa de um modelo semelhante.

### Objetivo desta análise

Propor um conjunto de permissões **granulares** que:
1. Permita criar cargos específicos (Operador, Caixa, Supervisor, Gerente POS, Admin POS).
2. Suporte os três portais propostos: `/pos/operador`, `/pos/gerente`, `/pos/admin`.
3. Controle operações sensíveis como cancelamento de venda, fecho de sessão, gestão de terminais, etc.
4. Seja compatível com o middleware `RequirePermission`/`RequirePermissionAny` existente.

---

## 2. Estado atual das permissões POS

### 2.1 Referências no código

| Permissão | Local | Uso |
|---|---|---|
| `pos:operar_pos` | `backend/internal/modules/pos/handlers/pos.go:112` | Cargo automático "Terminal POS" |
| `pos:operar_pos` | `backend/internal/modules/auth/handlers/pos_login.go:22` | Login de terminal POS |
| `pos` | `frontend/src/Routing/Pages/ComercialPageRoutes.php` | Permissão genérica para todas as páginas POS |

### 2.2 Cargos documentados

| Cargo | Permissões POS | Descrição |
|---|---|---|
| **Caixa** | `pos:ver,criar,editar,relatorios` | Operações de ponto de venda |

### 2.3 Problemas

1. **Permissão única demasiado ampla**: `pos:operar_pos` dá acesso total ao terminal.
2. **Não distingue operação de gestão**: quem vende não deve necessariamente configurar terminais.
3. **Não protege operações críticas**: cancelar venda, fechar sessão, estornar, movimentar caixa.
4. **Não alinha com portais**: não há permissões para gerente/admin.
5. **Middleware atual não usa ações específicas**: todas as rotas POS usam `permission => 'pos'`.

---

## 3. Referência: granularidade da Gestão Escolar

O módulo `gestao-escolar` define ações específicas além do CRUD genérico:

| Ação | Descrição |
|---|---|
| `ver` | Consultar dados |
| `relatorios` | Relatórios e dashboards |
| `gerir_turmas` | Turmas, professores, disciplinas |
| `gerir_alunos` | Alunos e encarregados |
| `gerir_matriculas` | Matrículas |
| `lancar_notas` | Notas de avaliação |
| `gerir_presencas` | Presenças/faltas |
| `gerir_horarios` | Horários |
| `gerir_calendario` | Calendário escolar |
| `gerir_propinas` | Cobranças e pagamentos |
| `gerir_biblioteca` | Livros e empréstimos |
| `gerir_ocorrencias` | Incidentes e sanções |
| `gerir_comunicacao` | Comunicados |
| `portal_aluno` | Gestão de acesso ao portal |
| `configurar` | Configurações gerais |

O POS deve seguir o mesmo padrão: ações específicas para domínios de negócio dentro do módulo.

---

## 4. Modelo de permissões granular proposto

### 4.1 Ações do módulo `pos`

#### Operações de caixa (Portal Operador)

| Ação | Descrição | Operações protegidas |
|---|---|---|
| `operar_pos` | Aceder ao terminal de venda | Abrir terminal, adicionar itens, pagar |
| `abrir_sessao` | Abrir sessão de caixa | `POST /api/pos/sessions/abrir` |
| `fechar_sessao` | Fechar sessão de caixa | `POST /api/pos/sessions/{id}/fechar` |
| `registar_venda` | Criar vendas | `POST /api/pos/sales` |
| `cancelar_venda` | Cancelar vendas | `POST /api/pos/sales/{id}/cancelar` |
| `processar_devolucao` | Registar devoluções | `POST /api/pos/returns` |
| `movimentar_caixa` | Entradas/saídas manuais de caixa | `POST /api/pos/sessions/{id}/cash-movements` |
| `aplicar_desconto` | Aplicar descontos em vendas | `POST /api/pos/descontos` (uso em venda) |

#### Gestão e configuração (Portal Admin)

| Ação | Descrição | Operações protegidas |
|---|---|---|
| `gerir_terminais` | Criar/editar/ativar terminais | `POST/PUT /api/pos/terminals/*` |
| `gerir_catalogo` | Gerir catálogo POS | `POST/PUT/DELETE /api/pos/catalogo/*` |
| `gerir_descontos` | Criar/editar regras de desconto | `POST/PUT/DELETE /api/pos/descontos` |
| `configurar` | Configurações gerais do POS | Configurações de série fiscal, métodos pagamento |

#### Relatórios e supervisão (Portal Gerente)

| Ação | Descrição | Operações protegidas |
|---|---|---|
| `ver` | Consultar vendas, sessões, terminais | `GET /api/pos/sales`, `GET /api/pos/sessions` |
| `relatorios` | Aceder a relatórios | `GET /api/pos/reports/*` |
| `supervisionar` | Ver sessões e vendas de outros operadores | Dashboard gerente, histórico |
| `fechar_outra_sessao` | Fechar sessão aberta por outro operador | `POST /api/pos/sessions/{id}/fechar` (sessão de outro) |

---

## 5. Mapeamento de permissões → Portais

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PORTAL OPERADOR                             │
│  /pos/operador/*                                                    │
│                                                                     │
│  Permissões necessárias:                                            │
│    • pos:operar_pos        (obrigatório)                            │
│    • pos:abrir_sessao                                                 │
│    • pos:fechar_sessao                                                │
│    • pos:registar_venda                                               │
│    • pos:cancelar_venda                                               │
│    • pos:processar_devolucao                                          │
│    • pos:movimentar_caixa                                             │
│    • pos:aplicar_desconto                                             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         PORTAL GERENTE                              │
│  /pos/gerente/*                                                     │
│                                                                     │
│  Permissões necessárias (pelo menos uma):                           │
│    • pos:relatorios                                                   │
│    • pos:supervisionar                                                │
│    • pos:fechar_outra_sessao                                          │
│                                                                     │
│  Também útil: pos:ver                                                 │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         PORTAL ADMIN                                │
│  /pos/admin/*                                                       │
│                                                                     │
│  Permissões necessárias (pelo menos uma):                           │
│    • pos:gerir_terminais                                              │
│    • pos:gerir_catalogo                                               │
│    • pos:gerir_descontos                                              │
│    • pos:configurar                                                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. Mapeamento de permissões → Endpoints

### 6.1 Endpoints core `/api/pos/*`

| Endpoint | Método | Permissão |
|---|---|---|
| `/api/pos/terminals` | GET | `pos:ver` ou `pos:gerir_terminais` |
| `/api/pos/terminals` | POST | `pos:gerir_terminais` |
| `/api/pos/terminals/{id}` | PUT | `pos:gerir_terminais` |
| `/api/pos/terminals/{id}/activar` | POST | `pos:gerir_terminais` |
| `/api/pos/terminals/{id}/desactivar` | POST | `pos:gerir_terminais` |
| `/api/pos/sessions/abrir` | POST | `pos:abrir_sessao` |
| `/api/pos/sessions/{id}` | GET | `pos:ver` |
| `/api/pos/sessions/{id}/resumo` | GET | `pos:ver` ou `pos:supervisionar` |
| `/api/pos/sessions/{id}/fechar` | POST | `pos:fechar_sessao` (própria) ou `pos:fechar_outra_sessao` (de outro) |
| `/api/pos/sessions/{id}/cash-movements` | GET/POST | `pos:movimentar_caixa` |
| `/api/pos/sales` | POST | `pos:registar_venda` |
| `/api/pos/sales` | GET | `pos:ver` ou `pos:supervisionar` |
| `/api/pos/sales/{id}` | GET | `pos:ver` |
| `/api/pos/sales/{id}/cancelar` | POST | `pos:cancelar_venda` |
| `/api/pos/sales/{id}/recibo` | GET | `pos:ver` ou `pos:operar_pos` |
| `/api/pos/returns` | POST | `pos:processar_devolucao` |
| `/api/pos/returns` | GET | `pos:ver` |
| `/api/pos/descontos` | GET/POST/PUT/DELETE | `pos:gerir_descontos` |
| `/api/pos/reports/*` | GET | `pos:relatorios` |
| `/api/pos/pagamentos/iniciar` | POST | `pos:registar_venda` |
| `/api/pos/pagamentos/{id}/status` | GET | `pos:operar_pos` |

### 6.2 Endpoints do portal `/api/pos/portal/*`

| Endpoint | Portal | Permissão |
|---|---|---|
| `/api/pos/portal/operador/sessao/atual` | Operador | `pos:operar_pos` |
| `/api/pos/portal/operador/sessao/abrir` | Operador | `pos:abrir_sessao` |
| `/api/pos/portal/operador/sessao/fechar` | Operador | `pos:fechar_sessao` |
| `/api/pos/portal/operador/vendas` | Operador | `pos:registar_venda` |
| `/api/pos/portal/operador/vendas/{id}/cancelar` | Operador | `pos:cancelar_venda` |
| `/api/pos/portal/operador/devolucoes` | Operador | `pos:processar_devolucao` |
| `/api/pos/portal/gerente/dashboard` | Gerente | `pos:relatorios` ou `pos:supervisionar` |
| `/api/pos/portal/gerente/vendas` | Gerente | `pos:supervisionar` |
| `/api/pos/portal/gerente/sessoes` | Gerente | `pos:supervisionar` |
| `/api/pos/portal/gerente/relatorios/*` | Gerente | `pos:relatorios` |
| `/api/pos/portal/admin/terminais` | Admin | `pos:gerir_terminais` |
| `/api/pos/portal/admin/catalogo` | Admin | `pos:gerir_catalogo` |
| `/api/pos/portal/admin/descontos` | Admin | `pos:gerir_descontos` |
| `/api/pos/portal/admin/configuracao` | Admin | `pos:configurar` |

---

## 7. Cargos-padrão POS recomendados

Ao criar um tenant, `auth.criar_cargos_padrao(tenant_id)` deveria criar:

| Cargo | Permissões `pos` | Descrição |
|---|---|---|
| **Operador de Caixa** | `operar_pos, abrir_sessao, fechar_sessao, registar_venda, processar_devolucao, movimentar_caixa, aplicar_desconto` | Vende no terminal, abre e fecha a própria sessão, faz movimentos de caixa. |
| **Caixa Sénior** | (todas as do Operador) + `cancelar_venda` | Pode cancelar vendas além de operar. |
| **Supervisor POS** | `ver, relatorios, supervisionar, fechar_outra_sessao` | Acompanha vários caixas, gera relatórios, pode fechar sessões de outros. |
| **Gerente de Loja** | `ver, relatorios, supervisionar, fechar_outra_sessao` + permissões de stock/produtos/faturação necessárias | Visão completa do POS e dos relatórios. |
| **Administrador POS** | `*` no módulo `pos` | Configura terminais, catálogo, descontos e regras do POS. |
| **Terminal POS** (sistema) | `operar_pos` | Cargo automático atribuído a contas de terminal. |

### 7.1 Exemplo de matriz

| Funcionalidade | Operador | Caixa Sénior | Supervisor | Gerente | Admin |
|---|---|:---:|:---:|:---:|:---:|
| Aceder terminal | ✅ | ✅ | — | — | — |
| Abrir sessão | ✅ | ✅ | — | — | — |
| Fechar própria sessão | ✅ | ✅ | — | — | — |
| Registar venda | ✅ | ✅ | — | — | — |
| Aplicar desconto | ✅ | ✅ | — | — | — |
| Movimentar caixa | ✅ | ✅ | — | — | — |
| Processar devolução | ✅ | ✅ | — | — | — |
| Cancelar venda | ❌ | ✅ | — | — | — |
| Ver vendas de outros | ❌ | ❌ | ✅ | ✅ | — |
| Fechar sessão de outro | ❌ | ❌ | ✅ | ✅ | — |
| Ver relatórios | ❌ | ❌ | ✅ | ✅ | — |
| Gerir terminais | ❌ | ❌ | ❌ | ❌ | ✅ |
| Gerir catálogo POS | ❌ | ❌ | ❌ | ❌ | ✅ |
| Gerir descontos | ❌ | ❌ | ❌ | ❌ | ✅ |
| Configurar POS | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 8. Alterações necessárias no código

### 8.1 Backend Go

#### a) Atualizar `backend/internal/modules/pos/handlers/pos.go`

O cargo "Terminal POS" deve continuar a ter apenas `operar_pos`:

```go
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES ($1, 'pos', 'operar_pos')
```

#### b) Atualizar rotas em `backend/internal/router/router.go`

Exemplo de como proteger endpoints com permissões específicas:

```go
// ── Operações de caixa ─────────────────────────────────────────────────────
r.Route("/api/pos", func(r chi.Router) {
    r.Use(mw.RequireAuth(cfg.JWTSecret, db, oauthKeys), mw.EnforceTenantHost(tenantHosts))

    // Terminais (admin)
    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "gerir_terminais"))
        r.Get("/terminals", pos.ListarTerminais)
        r.Post("/terminals", pos.CriarTerminal)
        r.Put("/terminals/{id}", pos.ActualizarTerminal)
        r.Post("/terminals/{id}/activar", pos.ActivarTerminal)
        r.Post("/terminals/{id}/desactivar", pos.DesactivarTerminal)
    })

    // Sessões
    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "abrir_sessao"))
        r.Post("/sessions/abrir", pos.AbrirSessao)
    })

    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "fechar_sessao"))
        r.Post("/sessions/{id}/fechar", pos.FecharSessao)
    })

    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "movimentar_caixa"))
        r.Get("/sessions/{id}/cash-movements", pos.ListarMovimentacoes)
        r.Post("/sessions/{id}/cash-movements", pos.CriarMovimentacao)
    })

    // Vendas
    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "registar_venda"))
        r.Post("/sales", pos.CriarVenda)
    })

    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "cancelar_venda"))
        r.Post("/sales/{id}/cancelar", pos.CancelarVenda)
    })

    // Devoluções
    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "processar_devolucao"))
        r.Post("/returns", pos.CriarDevolucao)
    })

    // Relatórios (gerente)
    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "relatorios"))
        r.Get("/reports/sales-by-session", pos.RelatorioVendasPorSessao)
        r.Get("/reports/sales-by-terminal", pos.RelatorioVendasPorTerminal)
        r.Get("/reports/sales-by-product", pos.RelatorioVendasPorProduto)
        r.Get("/reports/sales-by-hour", pos.RelatorioVendasPorHora)
        r.Get("/reports/cash-closing", pos.RelatorioFechoCaixa)
    })

    // Descontos (admin)
    r.Group(func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "gerir_descontos"))
        r.Get("/descontos", pos.ListarDescontos)
        r.Post("/descontos", pos.CriarDesconto)
        r.Put("/descontos/{id}", pos.ActualizarDesconto)
        r.Delete("/descontos/{id}", pos.RemoverDesconto)
    })
})
```

#### c) Criar helper para fecho de sessão de outro operador

No handler `FecharSessao`, verificar:

```go
if sessao.UserID != user.ID {
    // requer permissão adicional
    if !user.Can("pos", "fechar_outra_sessao") {
        jsonErr(w, "Sem permissão para fechar sessão de outro operador", http.StatusForbidden)
        return
    }
}
```

### 8.2 Frontend PHP

#### a) Atualizar `frontend/src/Routing/Pages/ComercialPageRoutes.php` (ou futuro `PosPageRoutes.php`)

```php
'pos_operator_terminal' => [
    'path' => '/pos/operador/terminal',
    'view' => 'pos/operator/terminal.php',
    'permission' => 'pos:operar_pos'
],
'pos_manager_dashboard' => [
    'path' => '/pos/gerente/dashboard',
    'view' => 'pos/manager/dashboard.php',
    'permission' => 'pos:relatorios'
],
'pos_admin_terminais' => [
    'path' => '/pos/admin/terminais',
    'view' => 'pos/admin/terminals.php',
    'permission' => 'pos:gerir_terminais'
],
```

#### b) Criar helper de permissões no frontend

```php
if ($app->user->can('pos', 'cancelar_venda')) {
    // mostrar botão cancelar
}
```

### 8.3 Banco de dados

Garantir que as novas ações sejam inseridas quando aplicável:

```sql
-- Cargos-padrão do POS (exemplo)
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
    ((SELECT id FROM auth.cargos WHERE nome='Operador de Caixa'), 'pos', 'operar_pos'),
    ((SELECT id FROM auth.cargos WHERE nome='Operador de Caixa'), 'pos', 'abrir_sessao'),
    ((SELECT id FROM auth.cargos WHERE nome='Operador de Caixa'), 'pos', 'fechar_sessao'),
    ((SELECT id FROM auth.cargos WHERE nome='Operador de Caixa'), 'pos', 'registar_venda'),
    ((SELECT id FROM auth.cargos WHERE nome='Operador de Caixa'), 'pos', 'processar_devolucao'),
    ((SELECT id FROM auth.cargos WHERE nome='Operador de Caixa'), 'pos', 'movimentar_caixa'),
    ((SELECT id FROM auth.cargos WHERE nome='Operador de Caixa'), 'pos', 'aplicar_desconto');
```

---

## 9. Considerações especiais

### 9.1 Terminal POS automático

A conta de terminal criada automaticamente (`terminal.{tenant}.{codigo}@nexora.local`) deve continuar com:
- Cargo "Terminal POS"
- Apenas `pos:operar_pos`

Isto garante que um dispositivo/tablet POS não pode cancelar vendas, fechar sessões de outros, nem aceder a relatórios.

### 9.2 Permissão `ver` vs `supervisionar`

- `pos:ver` → ver os próprios dados (vendas da própria sessão).
- `pos:supervisionar` → ver dados de todos os operadores/sessões.

### 9.3 Combinação de permissões

Um utilizador pode ter múltiplas permissões. Por exemplo, um **Caixa Sénio** pode ter:
- `operar_pos, abrir_sessao, fechar_sessao, registar_venda, cancelar_venda, processar_devolucao, movimentar_caixa, aplicar_desconto`

Um **Gerente de Loja** pode ter:
- `ver, relatorios, supervisionar, fechar_outra_sessao`

### 9.4 Compatibilidade retroativa

Para não quebrar utilizadores existentes:
1. Manter `pos:operar_pos` como permissão base.
2. Atualizar cargos existentes "Caixa" para incluir as novas permissões básicas.
3. Migrar `pos:ver,criar,editar,relatorios` → conjunto equivalente nas novas ações.

---

## 10. Roadmap de implementação

### Fase 1 — Definir ações
- [ ] Validar lista de ações proposta com stakeholders
- [ ] Atualizar `docs/CARGOS.md` com novas ações e cargos-padrão

### Fase 2 — Backend
- [ ] Atualizar rotas em `backend/internal/router/router.go` para usar permissões específicas
- [ ] Adicionar verificações especiais em operações sensíveis (ex: fechar sessão de outro)
- [ ] Criar/atualizar seeds de cargos-padrão

### Fase 3 — Frontend
- [ ] Atualizar `ComercialPageRoutes.php` (ou `PosPageRoutes.php`) com permissões por rota
- [ ] Adicionar/esconder botões e menus consoante permissões
- [ ] Criar página de "acesso negado" específica por portal

### Fase 4 — Migração
- [ ] Script SQL para converter permissões antigas `pos:ver,criar,editar,relatorios` nas novas
- [ ] Garantir que contas de terminal mantêm apenas `operar_pos`

### Fase 5 — Testes
- [ ] Testar cada cargo com cada endpoint
- [ ] Testar portal operador sem permissão de gerente
- [ ] Testar terminal POS limitado

---

## 11. Conclusão

A granularidade de permissões do POS deve evoluir de:

```
pos:operar_pos
pos:ver,criar,editar,relatorios
```

Para:

```
pos:operar_pos, abrir_sessao, fechar_sessao, registar_venda,
    cancelar_venda, processar_devolucao, movimentar_caixa,
    aplicar_desconto, gerir_terminais, gerir_catalogo,
    gerir_descontos, configurar, ver, relatorios, supervisionar,
    fechar_outra_sessao
```

Este modelo:
- Suporta os portais `/pos/operador`, `/pos/gerente`, `/pos/admin`.
- Permite criar cargos realistas (Operador, Caixa Sénior, Supervisor, Gerente, Admin POS).
- Protege operações críticas (cancelamento, fecho de sessão de outro, gestão de terminais).
- Alinha o POS com o padrão de granularidade já usado na Gestão Escolar.
