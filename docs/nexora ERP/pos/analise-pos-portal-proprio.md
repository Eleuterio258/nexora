# Análise: POS com Portal Próprio (igual ao Cenário da Escola)

**Data:** 2026-08-12  
**Âmbito:** Módulo POS do Nexora ERP
**Abordagem:** Manter o POS acoplado ao ERP, mas criar **portais dedicados por persona**, tal como a Escola fez com `/aluno`, `/escola` e `/portal/professor`.

---

## 1. Resumo executivo

O utilizador levantou uma ideia importante: **o POS pode ter um portal próprio**. Isto não contradiz a abordagem acoplada — significa que, dentro do mesmo ERP, o POS deve ter:

- **Rotas web dedicadas** por persona (operador, gerente, admin)
- **APIs segmentadas** por perfil
- **App mobile opcional** (`nexora_pos/`) consumindo essas APIs
- **Service layer próprio** no frontend PHP

Esta é exatamente a estratégia que a Escola usa com sucesso:

| Escola | POS proposto |
|---|---|
| `/escola/*` — admin escolar | `/pos/admin/*` — gestão de terminais, catálogo, descontos |
| `/aluno/*` — portal do aluno | `/pos/operador/*` — terminal de venda |
| `/portal/professor/*` — portal do professor | `/pos/gerente/*` — dashboard, relatórios, fechos |
| `/api/escolar/*` + `/api/portal/aluno/*` | `/api/pos/*` + `/api/pos/portal/*` |
| `nexora_school/` app Flutter | `nexora_pos/` app Flutter/Kotlin |

---

## 2. Porquê um portal próprio para o POS?

### 2.1 Vantagens

1. **Separação de responsabilidades por persona**:
   - Operador de caixa só vê o terminal de venda
   - Gerente vê relatórios, fechos e dashboards
   - Admin configura terminais, catálogo e descontos

2. **Permissões mais granulares**:
   - `pos:operar_pos` → portal do operador
   - `pos:gerir_terminais`, `pos:gerir_catalogo` → portal admin
   - `pos:relatorios`, `pos:fechar` → portal gerente

3. **Experiência de utilizador otimizada**:
   - Cada portal pode ter layout e menu próprios
   - O operador não vê menus de administração do ERP
   - O gerente não precisa de entrar no terminal de venda

4. **Preparação para app mobile**:
   - Um portal bem definido facilita a criação de `nexora_pos/`
   - As APIs `/api/pos/portal/*` servem tanto web como mobile

5. **Alinhamento com a estratégia da escola**:
   - Reutiliza padrões já estabelecidos no projeto
   - Facilita manutenção e onboarding de desenvolvedores

---

## 3. Estrutura de portais proposta

### 3.1 Portais web (frontend PHP)

```
/pos/operador/*      → Terminal de venda (o que hoje é /nexora/pos)
/pos/gerente/*       → Dashboard, relatórios, fechos de caixa
/pos/admin/*         → Terminais, catálogo POS, descontos, configuração
```

#### Mapeamento de páginas atuais

| Página atual | Novo portal | Rota proposta |
|---|---|---|
| `pos.php` | Operador | `/pos/operador/terminal` |
| `pos_dashboard.php` | Gerente | `/pos/gerente/dashboard` |
| `pos_vendas.php` | Gerente | `/pos/gerente/vendas` |
| `pos_venda_ver.php` | Gerente | `/pos/gerente/vendas/ver` |
| `pos_sessoes.php` | Gerente | `/pos/gerente/sessoes` |
| `pos_sessa_abrir.php` | Operador | `/pos/operador/sessao/abrir` |
| `pos_sessa_fecho.php` | Operador/Gerente | `/pos/operador/sessao/fechar` |
| `pos_sessa_detalhe.php` | Gerente | `/pos/gerente/sessoes/ver` |
| `pos_terminais.php` | Admin | `/pos/admin/terminais` |
| `pos_catalogo.php` | Admin | `/pos/admin/catalogo` |
| `pos_descontos.php` | Admin | `/pos/admin/descontos` |
| `pos_relatorios.php` | Gerente | `/pos/gerente/relatorios` |
| `pos_relatorio_fecho.php` | Gerente | `/pos/gerente/relatorios/fecho` |
| `pos_devolucoes.php` | Operador/Gerente | `/pos/operador/devolucoes` |

### 3.2 APIs segmentadas (backend Go)

```
/api/pos/*                    → Operações de caixa (já existe)
/api/pos/portal/operador/*    → Terminal, sessão, venda, devolução
/api/pos/portal/gerente/*     → Dashboard, relatórios, fechos, histórico
/api/pos/portal/admin/*       → Terminais, catálogo, descontos, configuração
```

#### Exemplos de rotas

**Portal Operador:**
```
GET    /api/pos/portal/operador/sessao/atual
POST   /api/pos/portal/operador/sessao/abrir
POST   /api/pos/portal/operador/sessao/fechar
POST   /api/pos/portal/operador/vendas
POST   /api/pos/portal/operador/vendas/{id}/cancelar
POST   /api/pos/portal/operador/devolucoes
POST   /api/pos/portal/operador/pagamentos/iniciar
```

**Portal Gerente:**
```
GET    /api/pos/portal/gerente/dashboard
GET    /api/pos/portal/gerente/vendas
GET    /api/pos/portal/gerente/vendas/{id}
GET    /api/pos/portal/gerente/sessoes
GET    /api/pos/portal/gerente/sessoes/{id}/resumo
GET    /api/pos/portal/gerente/relatorios/vendas-por-sessao
GET    /api/pos/portal/gerente/relatorios/vendas-por-terminal
GET    /api/pos/portal/gerente/relatorios/produtos-mais-vendidos
GET    /api/pos/portal/gerente/relatorios/fecho-caixa
```

**Portal Admin:**
```
GET    /api/pos/portal/admin/terminais
POST   /api/pos/portal/admin/terminais
PUT    /api/pos/portal/admin/terminais/{id}
POST   /api/pos/portal/admin/terminais/{id}/activar
POST   /api/pos/portal/admin/terminais/{id}/desactivar
GET    /api/pos/portal/admin/catalogo
POST   /api/pos/portal/admin/catalogo
DELETE /api/pos/portal/admin/catalogo/{id}
GET    /api/pos/portal/admin/descontos
POST   /api/pos/portal/admin/descontos
PUT    /api/pos/portal/admin/descontos/{id}
DELETE /api/pos/portal/admin/descontos/{id}
```

### 3.3 App mobile POS

```
nexora_pos/
├── android/
├── ios/
├── assets/
├── lib/
│   ├── core/              # Dio, secure storage, DI, config
│   └── features/
│       ├── auth/
│       ├── terminal/
│       ├── session/
│       ├── sale/
│       ├── catalog/
│       ├── returns/
│       ├── payments/
│       └── reports/
├── test/
├── README.md
└── pubspec.yaml
```

O app consome principalmente `/api/pos/portal/operador/*`.

---

## 4. Estrutura de diretórios proposta

### 4.1 Frontend PHP

```
frontend/src/
├── Routing/
│   └── Pages/
│       ├── PosPageRoutes.php          # novas rotas /pos/*
│       └── ComercialPageRoutes.php    # remover rotas pos antigas
├── Model/
│   └── Service/
│       └── Pos/
│           ├── PosOperatorService.php
│           ├── PosManagerService.php
│           └── PosAdminService.php
└── View/
    └── templates/
        ├── layouts/
        │   ├── pos_operator_top.php
        │   ├── pos_manager_top.php
        │   └── pos_admin_top.php
        └── pages/
            └── pos/
                ├── operator/
                │   ├── terminal.php
                │   ├── session_open.php
                │   └── session_close.php
                ├── manager/
                │   ├── dashboard.php
                │   ├── sales.php
                │   ├── sessions.php
                │   └── reports.php
                └── admin/
                    ├── terminals.php
                    ├── catalog.php
                    └── discounts.php
```

### 4.2 Backend Go

```
backend/internal/modules/pos/
├── handlers/
│   ├── handler.go
│   ├── pos.go                 # operações core (mantêm /api/pos/*)
│   ├── pagamentos.go
│   ├── movimentacoes.go
│   ├── devolucoes.go
│   ├── relatorios.go
│   ├── faturacao.go
│   ├── descontos.go
│   ├── recibo.go
│   ├── sync.go
│   └── portal/
│       ├── operator.go        # /api/pos/portal/operador/*
│       ├── manager.go         # /api/pos/portal/gerente/*
│       └── admin.go           # /api/pos/portal/admin/*
```

### 4.3 Router Go

Adicionar em `backend/internal/router/router.go`:

```go
// ── Portal POS ─────────────────────────────────────────────────────────────
r.Route("/api/pos/portal", func(r chi.Router) {
    r.Use(mw.RequireAuth(cfg.JWTSecret, db, oauthKeys), mw.EnforceTenantHost(tenantHosts))

    // Operador
    r.Route("/operador", func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "operar_pos"))
        r.Get("/sessao/atual", posPortal.ObterSessaoAtual)
        r.Post("/sessao/abrir", posPortal.AbrirSessao)
        r.Post("/sessao/fechar", posPortal.FecharSessao)
        r.Post("/vendas", posPortal.CriarVenda)
        // ...
    })

    // Gerente
    r.Route("/gerente", func(r chi.Router) {
        r.Use(mw.RequirePermissionAny(db, []authModels.Permission{
            {Modulo: "pos", Acao: "relatorios"},
            {Modulo: "pos", Acao: "fechar"},
        }))
        r.Get("/dashboard", posPortal.DashboardGerente)
        r.Get("/vendas", posPortal.ListarVendasGerente)
        // ...
    })

    // Admin
    r.Route("/admin", func(r chi.Router) {
        r.Use(mw.RequirePermission(db, "pos", "gerir_terminais"))
        r.Get("/terminais", posPortal.ListarTerminaisAdmin)
        r.Post("/terminais", posPortal.CriarTerminalAdmin)
        // ...
    })
})
```

---

## 5. Permissões por portal

| Portal | Permissões mínimas | Observação |
|---|---|---|
| `/pos/operador` | `pos:operar_pos` | Acesso apenas ao terminal de venda |
| `/pos/gerente` | `pos:relatorios` ou `pos:fechar` | Acesso a dashboards e relatórios |
| `/pos/admin` | `pos:gerir_terminais` ou `pos:gerir_catalogo` | Configuração do POS |

**Nota:** Um utilizador pode ter acesso a múltiplos portais se tiver as permissões combinadas.

---

## 6. Roadmap de implementação

### Fase 1 — Preparação
- [ ] Definir personas do POS (operador, gerente, admin)
- [ ] Mapear páginas atuais para os novos portais
- [ ] Criar permissões específicas se ainda não existirem
- [ ] Documentar APIs existentes `/api/pos/*`

### Fase 2 — Backend: criar APIs do portal
- [ ] Criar `backend/internal/modules/pos/handlers/portal/`
- [ ] Criar `operator.go`, `manager.go`, `admin.go`
- [ ] Registar rotas em `backend/internal/router/router.go`
- [ ] Garantir que os handlers reutilizam a lógica de `pos.go` (evitar duplicação)

### Fase 3 — Frontend: reorganizar rotas e páginas
- [ ] Criar `frontend/src/Routing/Pages/PosPageRoutes.php`
- [ ] Criar diretórios `frontend/src/View/templates/pages/pos/{operator,manager,admin}/`
- [ ] Mover/renomear páginas existentes
- [ ] Criar services `PosOperatorService`, `PosManagerService`, `PosAdminService`
- [ ] Remover rotas POS de `ComercialPageRoutes.php`
- [ ] Adicionar redirects de `/nexora/pos/*` para `/pos/*` (compatibilidade temporária)

### Fase 4 — Layouts e UI
- [ ] Criar layouts separados para cada portal
- [ ] Menu lateral por persona
- [ ] Redirecionar utilizador para o portal correto consoante permissões

### Fase 5 — App mobile (opcional)
- [ ] Criar/esboçar `nexora_pos/`
- [ ] Consumir `/api/pos/portal/operador/*`
- [ ] Implementar login de terminal/consumidor

### Fase 6 — Testes e depreciação
- [ ] Testar todos os fluxos por portal
- [ ] Remover redirects antigos
- [ ] Atualizar documentação

---

## 7. Dependências com outros módulos

Mesmo com portal próprio, o POS continua dependente de outros módulos. A recomendação do documento `analise-pos-acoplado-erp.md` mantém-se:

- Usar **Ports & Adapters** para faturação, stock, clientes, contabilidade, financeiro, tesouraria
- Evitar queries diretas a tabelas estrangeiras
- Documentar contratos entre módulos

O portal próprio resolve a **organização do frontend/API**, não o **acoplamento de backend**. Ambos os trabalhos podem e devem ser feitos em paralelo.

---

## 8. Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Refatoração de rotas quebra bookmarks/links internos | Médio | Manter redirects temporários de `/nexora/pos/*` para `/pos/*` |
| Duplicação de lógica entre `/api/pos/*` e `/api/pos/portal/*` | Médio | Os handlers do portal devem chamar funções/services do módulo POS core |
| Permissões mal configuradas expõem funcionalidades erradas | Alto | Testar cada portal com cada perfil de utilizador |
| Resistência de utilizadores a novas URLs | Baixo | Comunicar mudança; manter compatibilidade durante transição |
| Atraso por tentar fazer tudo de uma vez | Médio | Fasear: começar por `/pos/operador` e `/pos/gerente` |

---

## 9. Conclusão

A ideia de **portal próprio para o POS** é a estratégia correta para alinhar com o cenário da Escola sem separar fisicamente o projeto:

1. **Backend:** Manter `/api/pos/*` existente e adicionar `/api/pos/portal/{operador,gerente,admin}/*`.
2. **Frontend:** Criar portais dedicados em `/pos/operador/*`, `/pos/gerente/*`, `/pos/admin/*`.
3. **Mobile:** Futuramente criar `nexora_pos/` consumindo as APIs do portal operador.
4. **Acoplamento:** Continuar a organizar dependências com Ports & Adapters.

Isto dá ao POS a **sua própria identidade** dentro do ERP, tal como a Escola tem, sem os custos de separação total.
