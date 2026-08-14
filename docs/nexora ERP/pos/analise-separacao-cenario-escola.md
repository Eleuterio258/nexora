# Análise: Separar o Módulo POS igual ao Cenário da Escola

**Data:** 2026-08-12  
**Âmbito:** Módulo POS do Nexora ERP (`backend/internal/modules/pos`, `frontend/src/View/templates/pages/pos*.php`, `pos/`, `mobile/`)
**Referência:** Módulo Escolar (`nexora_school/`, `backend/internal/modules/gestao-escolar/`, portais PHP `/aluno`, `/escola`, `/portal/professor`)

---

## 1. Resumo executivo

O módulo Escolar está **bem segregado**:

- App mobile próprio → `nexora_school/` (Flutter)
- Backend dedicado → `backend/internal/modules/gestao-escolar/`
- Frontends web separados → `/aluno/*`, `/escola/*`, `/portal/professor/*`
- APIs segmentadas por perfil → `/api/escolar/*`, `/api/portal/aluno/*`, `/api/portal/professor/*`, `/api/portal/encarregado/*`
- Documentação própria → `nexora_school/README.md`, `ANALISE_ENDPOINTS_FALTANTES.md`, `docs/nexora ERP/gestao-escolar/`

O módulo POS **ainda não tem esse nível de separação**:

- O backend já está modularizado em `backend/internal/modules/pos/` ✅
- Mas o **frontend web real está dentro do `frontend/` PHP geral** (`frontend/src/View/templates/pages/pos*.php`)
- O diretório `pos/` na raiz é **apenas um mockup HTML estático** (`nexora_pos.html`)
- Existe um app mobile PayCore em `mobile/`, mas ainda não foi promovido a "cliente POS oficial do Nexora" e ainda aponta para backend Node.js próprio
- Não há README nem estrutura de projeto própria no `pos/`

**Conclusão:** O POS precisa de um "cliente próprio" (web/mobile) tal como a Escola tem o `nexora_school`. O backend Go já está no caminho certo; o gap principal está na **camada de apresentação/aplicação**.

---

## 2. Referência: como está a Escola

| Camada | Localização | Tecnologia | Observação |
|---|---|---|---|
| App mobile | `nexora_school/` | Flutter 3.10+ | Projeto independente com `pubspec.yaml`, package name próprio, splash/ícone próprios |
| Backend | `backend/internal/modules/gestao-escolar/` | Go | Módulo isolado: handlers, services, repositories, models |
| APIs | `/api/escolar/*`, `/api/portal/aluno/*`, `/api/portal/professor/*`, `/api/portal/encarregado/*` | REST | Rotas separadas por perfil |
| Web portals | `/aluno/*`, `/escola/*`, `/portal/professor/*` | PHP frontend | Frontends separados dentro do `frontend/`, mas com rotas dedicadas |
| Arquitetura mobile | Clean Architecture + Feature-First | BLoC/Cubit + Dio + GetIt | `lib/core/` + `lib/features/<feature>/data/domain/presentation` |
| Documentação | `nexora_school/README.md`, `ANALISE_ENDPOINTS_FALTANTES.md` | Markdown | Como correr, endpoints consumidos, gaps |

### Estrutura do app escolar

```
nexora_school/
├── android/
├── ios/
├── assets/
├── lib/
│   ├── core/           # Dio, secure storage, DI, config
│   └── features/       # auth, student_portal, teacher, agenda, onboarding, splash
├── test/
├── README.md
├── ANALISE_ENDPOINTS_FALTANTES.md
└── pubspec.yaml
```

---

## 3. Estado atual do POS

### 3.1 Backend (já modularizado ✅)

```
backend/internal/modules/pos/
└── handlers/
    ├── handler.go
    ├── pos.go              # terminais, sessões, vendas
    ├── pagamentos.go
    ├── movimentacoes.go
    ├── devolucoes.go
    ├── relatorios.go
    ├── faturacao.go
    ├── estorno_parcial.go
    ├── descontos.go
    ├── recibo.go
    ├── sync.go
    ├── paycore_transactions.go
    └── licenca.go
```

**APIs existentes:** `/api/pos/*` (terminais, sessões, vendas, pagamentos, devoluções, movimentos, relatórios)

**Dependências do backend POS:**
- `gestao-produtos` → `product_id` nas linhas de venda
- `gestao-stock` → baixa de stock no `warehouse_id` do terminal
- `modulo-faturacao` → geração de fatura fiscal (série "FT")
- `financeiro` → recebimentos por método de pagamento
- `tesouraria` → `caixa_id` do terminal; reconciliação no fecho
- `contabilidade` → lançamentos contabilísticos automáticos
- `recursos-humanos` → `funcionario_id` do operador
- `auth` → permissões `pos:operar_pos`, `pos:gerir_terminais`, etc.
- `nexorapay` → M-Pesa/eMola
- `ws` / `push` → notificações

### 3.2 Frontend web (acoplado ao ERP web ❌)

```
frontend/src/View/templates/pages/
├── pos.php
├── pos_catalogo.php
├── pos_dashboard.php
├── pos_descontos.php
├── pos_devolucoes.php
├── pos_relatorios.php
├── pos_relatorio_fecho.php
├── pos_sessa_abrir.php
├── pos_sessa_detalhe.php
├── pos_sessa_fecho.php
├── pos_sessoes.php
├── pos_terminais.php
├── pos_vendas.php
└── pos_venda_ver.php
```

- O POS é servido pelo mesmo container PHP do ERP (`docker-compose.yml` serviço `web`)
- Usa o layout POS próprio (`pos_top.php`, `pos_bottom.php`, `pos_end.php`) mas ainda vive dentro do `frontend/`
- Rota principal: `/nexora/pos`

### 3.3 App mobile (em transição ⚠️)

```
mobile/
├── app/                          # Android/Kotlin (PayCore)
├── Fluxo_Telas_PVD_Mobile.md
├── Analise_Backend_Go_factPro_vs_Modelo_Nexora.md
├── Analise_Completa_dos_Arquivos_Kotlin_Lacunas_do_Aplicativo.md
├── Analise_Fluxo_Autenticacao_vs_Modelo_Nexora.md
└── Lacunas_Fluxo_Autenticacao_vs_Telas_PVD.md
```

- App PayCore (Kotlin) existe e já foi analisado para usar o backend Go do Nexora
- Ainda aponta para backend Node.js próprio (`PayCore/backend`)
- Tem lacunas de auth, login mock, BASE_URL hardcoded, etc.
- **Não está renomeado/organizado como `nexora_pos/` nem promovido a cliente oficial**

### 3.4 Protótipo estático (obsoleto)

```
pos/
├── images/               # imagens de produtos de exemplo
├── nexora_pos.html       # mockup HTML estático
└── nexora_web_pos.png    # screenshot
```

- O diretório `pos/` na raiz **não é a aplicação POS real**
- É apenas um mockup UI/UX antigo com produtos hard-coded

---

## 4. Gap Analysis: POS vs Escola

| Critério | Escola ✅ | POS ❌/⚠️ | Gap |
|---|---|---|---|
| **App mobile dedicado** | `nexora_school/` projeto Flutter independente | `mobile/` existe (PayCore Kotlin) mas não promovido a cliente oficial | Renomear/reorganizar `mobile/` → `nexora_pos/` ou criar `nexora_pos/` novo |
| **Backend dedicado** | `backend/internal/modules/gestao-escolar/` | `backend/internal/modules/pos/` ✅ | Já está OK |
| **APIs segmentadas** | `/api/portal/aluno/*`, `/api/portal/professor/*`, `/api/escolar/*` | `/api/pos/*` ✅ | Já está OK; pode criar `/api/portal/pos/*` para operadores se necessário |
| **Frontend web separado** | `/aluno/*`, `/escola/*`, `/portal/professor/*` | POS está em `/nexora/pos` dentro do ERP web | Extrair POS do `frontend/` para um projeto próprio (PWA/SPA) |
| **Arquitetura limpa no cliente** | Clean + Feature-First + BLoC/Cubit | Frontend PHP monolítico; app mobile com dívida técnica | Aplicar arquitetura modular no novo cliente POS |
| **README próprio** | `nexora_school/README.md` + `ANALISE_ENDPOINTS_FALTANTES.md` | `pos/` não tem README; docs estão em `docs/nexora ERP/pos/` | Criar `pos/README.md` ou `nexora_pos/README.md` |
| **Build/Docker próprio** | Flutter build nativo | POS compartilha container PHP com ERP | Criar Dockerfile/serviço próprio para o frontend POS |
| **Design system/SDK partilhado** | App escolar tem cores/assets próprios | POS usa `nexora.css` e fontes do ERP web | Definir design system próprio ou reaproveitar |

---

## 5. Proposta de separação em 4 camadas

Para o POS ficar separado igual à Escola, propomos:

### 5.1 Camada 1 — Backend (manter/ajustar)

**Ação:** Manter `backend/internal/modules/pos/` como backend dedicado.

**Ajustes necessários:**
- Considerar criar sub-rotas por persona:
  - `/api/pos/operador/*` → operação de caixa
  - `/api/pos/admin/*` → gestão de terminais, catálogo, relatórios
  - `/api/pos/portal/*` → dashboards/relatórios para gerentes
- Garantir que o módulo POS tenha contratos bem definidos (`internal/shared/contracts`) para dependências (faturação, stock, financeiro, tesouraria)
- Generalizar autenticação de terminal/dispositivo para suportar app mobile (ver análise PayCore)

### 5.2 Camada 2 — Frontend Web POS separado

**Ação:** Extrair o POS do `frontend/` para um projeto próprio.

**Opções:**

| Opção | Descrição | Prós | Contras |
|---|---|---|---|
| **A — SPA/PWA em novo diretório** | Criar `pos/` (ou `nexora_pos_web/`) com Vue/React/Angular ou até HTML/JS moderno | Totalmente separado, pode ser instalado como app em tablets/kiosks | Mais um projeto para manter |
| **B — Sub-aplicação PHP separada** | Criar `nexora_pos/` com PHP próprio, mas separado do `frontend/` | Reaproveita know-how PHP da equipa | Ainda depende de PHP |
| **C — Manter no frontend mas isolar rotas** | Deixar em `frontend/` mas com rotas/API isoladas | Menor esforço imediato | Não é "separado igual à escola" |

**Recomendação:** Opção A — criar um PWA moderno (pode ser Flutter Web, React ou Vue) em `pos/` ou `nexora_pos_web/`, consumindo diretamente `/api/pos/*`.

### 5.3 Camada 3 — App Mobile POS

**Ação:** Promover o `mobile/` (PayCore) a cliente POS oficial do Nexora.

**Passos:**
1. Renomear/estruturar `mobile/` → `nexora_pos/` (opcional, mas alinha nomenclatura com `nexora_school`, `nexora_pay`, `nexora_recrutamento`)
2. Corrigir dívida técnica:
   - Login mock → real
   - `BASE_URL` hardcoded → build variants dev/staging/prod
   - Logging `BODY` desligado em release
   - Firebase configurado corretamente
3. Implementar auth de terminal no ERP (extensão do módulo POS)
4. Migrar endpoints da app de `PayCore/backend` para `/api/pos/*` do Nexora
5. Aplicar arquitetura Clean/Feature-First similar ao `nexora_school`:

```
nexora_pos/
├── android/
├── ios/
├── assets/
├── lib/
│   ├── core/           # Dio, secure storage, DI, config
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

**Nota:** Se a equipa preferir manter Kotlin, a estrutura deve espelhar a mesma separação por feature.

### 5.4 Camada 4 — Documentação e organização

**Ação:** Criar documentação própria do POS.

- `pos/README.md` ou `nexora_pos/README.md`:
  - O que é o POS Nexora
  - Tecnologias
  - Como correr
  - Endpoints consumidos
  - Conta de teste
- `ANALISE_ENDPOINTS_FALTANTES.md` equivalente
- Atualizar `docs/nexora ERP/pos/` com arquitetura de separação
- Criar `docker-compose` próprio ou serviço separado se for SPA/PWA

---

## 6. Roadmap sugerido

### Fase 0 — Decisão de arquitetura
- [ ] Escolher tecnologia do cliente POS web (PWA Flutter/React/Vue/PHP separado)
- [ ] Decidir se promove `mobile/` para `nexora_pos/` ou cria novo
- [ ] Definir design system/SDK compartilhado com outros apps Nexora

### Fase 1 — Backend POS (ajustes)
- [ ] Criar/auth de terminal/dispositivo móvel no módulo POS
- [ ] Segmentar APIs por persona se necessário (`/api/pos/operador/*`, `/api/pos/admin/*`)
- [ ] Garantir contratos bem definidos com faturação/stock/financeiro/tesouraria
- [ ] Endpoint genérico de registo de push token para utilizadores POS

### Fase 2 — Frontend Web POS separado
- [ ] Criar novo projeto em `pos/` ou `nexora_pos_web/`
- [ ] Migrar telas de `frontend/src/View/templates/pages/pos*.php`
- [ ] Consumir `/api/pos/*` diretamente
- [ ] Dockerfile/serviço Docker próprio
- [ ] README e documentação

### Fase 3 — App Mobile POS
- [ ] Corrigir dívida técnica do `mobile/`
- [ ] Renomear para `nexora_pos/` (opcional)
- [ ] Implementar login de terminal contra ERP
- [ ] Migrar endpoints para `/api/pos/*`
- [ ] Aplicar Clean Architecture/Feature-First

### Fase 4 — Integração e testes
- [ ] Testes end-to-end web + mobile
- [ ] Testes de carga (venda < 3s conforme RNF03)
- [ ] Testes de sincronização offline (se aplicável)

### Fase 5 — Depreciar POS antigo no frontend
- [ ] Remover `frontend/src/View/templates/pages/pos*.php`
- [ ] Remover rotas POS do `frontend/src/Routing/Pages/ComercialPageRoutes.php`
- [ ] Atualizar `docker-compose.yml` se necessário

---

## 7. Riscos e dependências críticas

| Risco | Impacto | Mitigação |
|---|---|---|
| POS depende de 8+ módulos do ERP | Alto | Manter contratos (`internal/shared/contracts`) estáveis; não quebrar APIs |
| Migração do frontend PHP para SPA/PWA pode perder funcionalidades | Médio | Mapear todas as telas e endpoints antes de migrar; fasear |
| App mobile PayCore tem dívida técnica significativa | Alto | Fase 0 de higiene antes de integrar com ERP |
| Autenticação de terminal ainda não existe no ERP | Alto | Construir como extensão do módulo POS; não reaproveitar `device_auth.go` (hardware) |
| Gateway Nexora-Pay só está integrado em pagamentos escolares | Médio | Generalizar gateway para o fluxo POS |
| Multi-tenant / resolução de tenant por host | Médio | Garantir que novo cliente POS envia/recebe headers/hosts corretos |
| Sessão offline / operação sem internet | Médio | Definir estratégia de sync (não existe hoje) |

---

## 8. Próximos passos recomendados

1. **Aprovar arquitetura-alvo**: decidir se o POS separado será Flutter (igual à escola) ou Kotlin/PWA.
2. **Criar/esboçar o novo projeto**: iniciar `nexora_pos/` ou `pos/` com estrutura base.
3. **Começar pelo backend**: finalizar auth de terminal e contratos antes de tocar nos clientes.
4. **Migrar frontend web por fases**: primeiro o terminal de venda (`pos.php`), depois gestão e relatórios.
5. **Sincronizar com app mobile**: aproveitar análises já feitas em `mobile/Analise_*.md`.

---

## 9. Conclusão

O **backend POS já está separado** igual ao backend da escola. O gap principal está no **cliente**: o POS web ainda vive dentro do `frontend/` PHP e o app mobile PayCore ainda não foi promovido a cliente oficial.

Para estar "separado igual ao cenário da escola", o POS precisa de:

1. ✅ Backend dedicado (já existe)
2. ❌ Frontend web próprio e separado do ERP
3. ❌ App mobile POS oficial (`nexora_pos/`) com arquitetura limpa
4. ❌ README e documentação de análise de gaps no próprio diretório

A separação é viável e segue o mesmo padrão da escola, mas requer decisões de produto/arquitetura antes da implementação.
