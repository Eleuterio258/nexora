# 📱 ANÁLISE POR MÓDULO - App Mobile OmniSysERP

> **Referência:** [backend/docs/spec.md v1.4](../../backend/docs/spec.md) — Especificação Funcional do Backend
> **Data:** 2026-04-24
> **Escopo:** cobertura mobile dos módulos operacionais do OmniSysERP

---

## 🎯 **CONTEXTO**

Considerando que **cada módulo tem suas próprias páginas**, este documento analisa o que o app mobile cobre face aos módulos definidos em `backend/docs/spec.md` e identifica o estado atual.

O backend aplica **controlo de acesso em quatro camadas**: autenticação → escopo de sistema → escopo de administração do tenant → escopo de módulo e permissão. O mobile deve respeitar o mesmo contrato.

**Roles globais válidos (spec):**
- `super-admin` — administra a plataforma (tenants, planos); **sem acesso operacional ao tenant**.
- `funcionario` — opera dentro do tenant conforme o seu **cargo**.

**Status geral do app:** 19 módulos operacionais ligados ao backend por `screens/modules/moduleApi.js`, telas de assiduidade completas (fluxo `funcionario`), dashboards de gestor, e navegação `super-admin` para tenants/planos. A maioria dos módulos operacionais ainda exibe **listagens básicas** vindas da API, com formulários de criação/edição e fluxos avançados por implementar.

---

## 📊 **ESTRUTURA ATUAL DOS MÓDULOS**

Os 19 módulos operacionais do mobile mapeiam 1:1 com os **módulos de cargo** definidos em spec.md:

> `dashboard`, `sales`, `categories`, `products`, `customers`, `series`, `crm`, `payroll`, `hr`, `signatures`, `quotes`, `orders`, `deliveries`, `invoices`, `receipts`, `credit-notes`, `returns`, `reports`, `settings`.

### **Organização por domínio funcional (alinhada com spec.md)**

#### 🏪 **1. COMERCIAL — Fluxo de ponta a ponta** (6 módulos)

Cobrem a progressão `Proposta → Pedido → Entrega → Faturação → Recebimento` definida no módulo *Fluxo Comercial* do spec.

| Módulo | Tela | Permissões (spec) | Estado |
|--------|------|-------------------|--------|
| **Vendas** (`sales`) | `ModuleSalesScreen.js` | módulo `sales` | ⚠️ Lista API / sem CRUD avançado |
| **Cotações** (`quotes`) | `ModuleQuotesScreen.js` | `quote.view`, `quote.create`, `quote.approve`, `quote.delete` | ⚠️ Lista API / sem criação |
| **Encomendas** (`orders`) | `ModuleOrdersScreen.js` | `order.view`, `order.create`, `order.approve`, `order.cancel` | ⚠️ Lista API / sem criação |
| **Entregas** (`deliveries`) | `ModuleDeliveriesScreen.js` | `delivery.view`, `delivery.create`, `delivery.confirm`, `delivery.cancel` | ⚠️ Lista API / sem confirmação |
| **Clientes** (`customers`) | `ModuleCustomersScreen.js` | `client.view`, `client.create`, `client.edit`, `client.delete` | ⚠️ Lista API / sem formulário |

#### 📦 **2. CATÁLOGO** (3 módulos)

Sustentam o catálogo e as sequências documentais.

| Módulo | Tela | Permissões (spec) | Estado |
|--------|------|-------------------|--------|
| **Produtos** (`products`) | `ModuleProductsScreen.js` | `product.view`, `product.create`, `product.edit`, `product.delete` | ⚠️ Lista API / sem scanner |
| **Categorias** (`categories`) | `ModuleCategoriesScreen.js` | `category.create`, `category.delete` | ⚠️ Lista API / sem árvore |
| **Séries Documentais** (`series`) | `ModuleSeriesScreen.js` | `series.manage` | ⚠️ Lista API / sem edição |

#### 💰 **3. FATURAÇÃO E REGULARIZAÇÕES** (4 módulos)

Agrupa a parte **documental e financeira** do fluxo comercial. Conforme spec, **Folha Salarial não pertence a este grupo** — é do domínio de Payroll/RH.

| Módulo | Tela | Permissões (spec) | Estado |
|--------|------|-------------------|--------|
| **Faturas** (`invoices`) | `ModuleInvoicesScreen.js` | `invoice.view`, `invoice.create`, `invoice.void` | ⚠️ Lista API / sem emissão |
| **Recibos** (`receipts`) | `ModuleReceiptsScreen.js` | `receipt.view`, `receipt.create`, `receipt.void` | ⚠️ Lista API / sem registo |
| **Notas de Crédito** (`credit-notes`) | `ModuleCreditNotesScreen.js` | `credit_note.view`, `credit_note.create`, `credit_note.void` | ⚠️ Lista API / sem criação |
| **Devoluções** (`returns`) | `ModuleReturnsScreen.js` | `return.view`, `return.create`, `return.approve` | ⚠️ Lista API / sem fluxo |

#### 👥 **4. PESSOAS — RH, Payroll e CRM** (3 módulos)

| Módulo | Tela | Permissões (spec) | Estado |
|--------|------|-------------------|--------|
| **RH** (`hr`) | `ModuleHRScreen.js` + fluxos `funcionario/*` (assiduidade, férias, chat, agenda) | `employee.view`, `employee.create`, `employee.edit`, `employee.delete`, `attendance.view`, `attendance.manage`, `leave.view`, `leave.approve` | ✅ Assiduidade completa / ⚠️ CRUD funcionário parcial |
| **Folha Salarial** (`payroll`) | `ModulePayrollScreen.js` | `payroll.view`, `payroll.process`, `payroll.approve` | ⚠️ Lista API / sem processamento |
| **CRM** (`crm`) | `ModuleCRMScreen.js` + `gestor/CRMScreen.js` | `crm.lead.create`, `crm.deal.create`, `crm.activity.create` | ⚠️ Lista API / pipeline visual básico |

#### 📄 **5. DOCUMENTAL** (1 módulo)

| Módulo | Tela | Permissões (spec) | Estado |
|--------|------|-------------------|--------|
| **Assinaturas Digitais** (`signatures`) | `ModuleSignaturesScreen.js` | `signature.create`, `signature.send` | ⚠️ Lista API / sem envio |

#### 📈 **6. GESTÃO E PLATAFORMA** (3 módulos)

| Módulo | Tela | Permissões (spec) | Estado |
|--------|------|-------------------|--------|
| **Dashboard** (`dashboard`) | `ModuleDashboardScreen.js` + `gestor/DashboardScreenGestor.js` | acesso ao módulo `dashboard` | ⚠️ Placeholder com alguns cards |
| **Relatórios** (`reports`) | `ModuleReportsScreen.js` | `report.view`, `report.export` | ⚠️ Lista API / sem exportação |
| **Configurações** (`settings`) | `ModuleSettingsScreen.js` | `settings.manage` (+ `admin.tenant` recomendado) | ⚠️ Lista API / sem escrita |

---

## 🔑 **MAPA DE PERMISSÕES MOBILE ↔ SPEC**

A UI mobile deve **esconder/desabilitar ações** conforme as permissões do cargo retornadas em `/auth/login`. O contrato da spec define as permissões operacionais abaixo como as únicas válidas:

```
admin.tenant
quote.{view,create,approve,delete}
order.{view,create,approve,cancel}
delivery.{view,create,confirm,cancel}
invoice.{view,create,void}
receipt.{view,create,void}
credit_note.{view,create,void}
return.{view,create,approve}
client.{view,create,edit,delete}
product.{view,create,edit,delete}
category.{create,delete}
series.manage
stock.{view,adjust}
employee.{view,create,edit,delete}
attendance.{view,manage}
leave.{view,approve}
payroll.{view,process,approve}
crm.{lead.create,deal.create,activity.create}
signature.{create,send}
report.{view,export}
notification.create
wms.{manage,sync}
settings.manage
```

Além das permissões de módulo, o backend suporta **permissões granulares** com escopo `own` / `dept` / `all` e condições contextuais (ex.: `invoice.approve.up_to_5000`). O mobile deve consumir `GET /api/admin/usuarios/{id}/granular-permissions` quando relevante e **respeitar o escopo** nas queries de listagem.

### **Lacunas técnicas conhecidas (spec — secção "Lacunas técnicas")**

A spec regista que várias permissões **ainda não estão implementadas como constantes** no backend e rotas de escrita **ainda não aplicam guards**. O mobile não deve presumir a enforcement: validar o retorno da API e **esconder ações reativa** quando vier 403.

---

## 🔍 **ANÁLISE DETALHADA POR MÓDULO**

### 📊 **DASHBOARD** (`dashboard`)

**Spec:** módulo em expansão funcional, leitura executiva transversal. Placeholder no backend.

**Estado atual no mobile:**
- ✅ `ModuleDashboardScreen.js` com cards de métricas (clientes, leads, atividades, pipeline)
- ✅ `gestor/DashboardScreenGestor.js` com barra de presença, WebSocket badge "live", breakdown por método
- ✅ Loading states, error handling, pull-to-refresh
- ❌ Sem drill-down nem filtros por período
- ❌ Dados agregados do endpoint ainda simplificados (backend também em placeholder)

**Próximos passos:**
1. Drill-down por KPI
2. Filtros por período (dia/semana/mês)
3. Alinhar com KPIs do backend quando saírem de placeholder (v1.4 — BI avançado já implementado)

---

### 🏪 **FLUXO COMERCIAL** — `sales`, `quotes`, `orders`, `deliveries`, `invoices`, `receipts`, `credit-notes`, `returns`

**Spec (progressão):** `Proposta → Pedido → Entrega → Faturação → Recebimento → (Notas de crédito / Devoluções)`.

**Cotações (`quotes`) — `ModuleQuotesScreen`**
- Listagem API já existe
- Criação (`quote.create`), aprovação (`quote.approve`) e conversão em encomenda ausentes
- Spec: `quote.approve` **não implica** `quote.create`

**Encomendas (`orders`) — `ModuleOrdersScreen`**
- Listagem API existe; falta criação, aprovação, cancelamento
- Spec: cancelar após entrega associada **exige fluxo de devolução**

**Entregas (`deliveries`) — `ModuleDeliveriesScreen`**
- Listagem API existe
- Falta geração a partir de encomenda aprovada, confirmação logística, anexo de POD (assinatura / foto)
- Spec: confirmação pode **desencadear sincronização WMS**

**Faturas (`invoices`) — `ModuleInvoicesScreen`**
- Listagem API existe; falta emissão, anulação (`invoice.void`) e PDF viewer
- Spec: anulação **pode exigir nota de crédito associada**

**Recibos (`receipts`) — `ModuleReceiptsScreen`**
- Listagem API existe; faltam novos recibos, métodos de pagamento, reconciliação bancária
- Spec: `receipt.void` reverte recebimento — operação sensível

**Notas de Crédito (`credit-notes`) — `ModuleCreditNotesScreen`**
- Listagem API existe; falta emissão a partir de fatura
- Spec: **sempre** associada a uma fatura existente

**Devoluções (`returns`) — `ModuleReturnsScreen`**
- Listagem API existe; faltam registo, aprovação e geração de NC automática
- Spec: aprovação **pode gerar movimentação de stock e nota de crédito**

**Clientes (`customers`) — `ModuleCustomersScreen`**
- Listagem API existe; falta detalhe/ficha comercial, contactos, histórico
- Spec: `client.delete` **não deve ser possível** para clientes com faturas/recibos/encomendas ativas

---

### 📦 **CATÁLOGO** — `products`, `categories`, `series`

**Produtos (`products`) — `ModuleProductsScreen`**
- Listagem API existe
- Falta: scanner de código de barras, variantes, fotos, gestão de stock por armazém
- Spec: produtos com stock ou documentos **não devem ser eliminados** — preferir desativação

**Categorias (`categories`) — `ModuleCategoriesScreen`**
- Listagem API existe
- Falta: árvore hierárquica, atribuição de produtos, drag-drop
- Spec: **não eliminar** categorias com produtos associados

**Séries Documentais (`series`) — `ModuleSeriesScreen`**
- Listagem API existe
- Falta: configuração de sequências, ativação/desativação, reset de contadores
- Spec: **desativar série em uso interrompe emissão** de documentos dessa série

---

### 💰 **FATURAÇÃO E REGULARIZAÇÕES**

Ver "FLUXO COMERCIAL" — as permissões `invoice.*`, `receipt.*`, `credit_note.*`, `return.*` são granulares conforme spec.

**⚠️ Correção face à versão anterior deste documento:** `payroll` foi removido deste grupo e movido para **PESSOAS (RH e Payroll)**, alinhando com a organização do spec (Folha Salarial é um domínio próprio associado a RH).

---

### 👥 **PESSOAS — RH, Payroll, CRM**

#### **Recursos Humanos (`hr`) — `ModuleHRScreen` + fluxos `funcionario/*`**

Spec v1.4 cobre: estrutura organizacional, onboarding, gestão de pessoas, contratos, documentos, **assiduidade**, ausências e licenças, **desempenho**, **formação e certificações** (v1.4), **portal do colaborador** (v1.4), offboarding.

**Estado mobile:**
- ✅ **Assiduidade** completa no app funcionário: `FaceScreen` (biometria), `NFCScreen`, `QRCodeScreen`, `SelfieGPSScreen`, `PINScreen`, `HistoricoScreen`
- ✅ **Ausências**: `SolicitarFeriasScreen`, `SolicitarFeriasFormScreen`, `JustificarScreen`
- ✅ **Gestor**: `EquipaScreenGestor`, `DetalheFuncionarioScreen`, `PedidoFeriasScreen`, `RegistarManualScreen`, `OcorrenciasScreen`
- ❌ **CRUD funcionários** completo no módulo ERP (`ModuleHRScreen` só lista)
- ❌ **Contratos** e **documentos do funcionário**
- ❌ **Portal do colaborador** completo (autosserviço avançado)
- ❌ **Formação e certificações** (v1.4)

**Regras do spec a respeitar no mobile:**
- desativação > eliminação quando há histórico
- fecho de assiduidade é **pré-requisito** do payroll do mesmo período
- pedidos aprovados **atualizam saldo** e registo de assiduidade automaticamente
- `leave.approve` pode estar **limitado à hierarquia** do aprovador

#### **Folha Salarial (`payroll`) — `ModulePayrollScreen`**

- Listagem de resultados existe
- Faltam: processamento de ciclo (`payroll.process`), aprovação (`payroll.approve`), recibos PDF, simulação
- Spec: fluxo correto é `payroll.process → payroll.approve`; consulta (`payroll.view`) é independente
- **Alerta do spec:** no router atual `payroll.process` está colapsado em `payroll.approve` — a separação será reforçada

#### **CRM (`crm`) — `ModuleCRMScreen` + `gestor/CRMScreen`**

Spec cobre: contas, contactos, leads, **deals** (pipeline, probabilidade, valor, previsão, geração de fatura), atividades, comunicações, **campanhas** (com origem, público-alvo, orçamento), **atendimento ao cliente** (tickets integrados).

**Estado mobile:**
- ✅ Visualização de pipeline e listagens
- ❌ Formulários de criação de leads / deals / atividades (requerem `crm.lead.create`, `crm.deal.create`, `crm.activity.create`)
- ❌ Campanhas e listas-alvo
- ❌ Tickets de atendimento (pós-venda)

**Funcionalidades mobile a adicionar (alinhadas com spec):**
- Integração com chamada / email / WhatsApp business
- Geolocalização de atividade (`GPS`) para visitas comerciais
- Conversão de oportunidade → fatura (`invoice.create`)

---

### 📄 **DOCUMENTAL — Assinaturas Digitais (`signatures`)**

**Spec:** preparação documental, envio para assinatura, fluxo externo com validação de identidade por OTP, verificação pública.

**Estado mobile:**
- Listagem API existe
- Falta: criar documento (`signature.create`), enviar (`signature.send`), acompanhar estado
- Mobile deve suportar **captura de assinatura** (signature pad) e **OTP** para validação

---

### 📈 **GESTÃO E PLATAFORMA — Reports, Settings**

**Relatórios (`reports`) — `ModuleReportsScreen`**
- Listagem API existe
- Falta: gráficos interativos, filtros, exportação (`report.export`), agendamento
- Spec: `report.export` pressupõe `report.view`

**Configurações (`settings`) — `ModuleSettingsScreen`**
- Listagem API existe; falta escrita (`settings.manage`)
- Spec: **recomendado combinar com `admin.tenant`**
- **Alerta do spec:** `PUT /api/settings/` ainda não aplica guard de `settings.manage` — mobile deve validar pelo lado do servidor

---

## 🧭 **FLUXOS ESPECIAIS DO APP (fora dos 19 módulos de cargo)**

O mobile também cobre áreas que no spec não são "módulos de cargo" mas são **áreas funcionais do backend**:

| Área do spec | Fluxos mobile | Observação |
|--------------|---------------|------------|
| **Auth** | `LoginScreen`, `ForgotPasswordScreen`, fluxo JWT | Token + tenant + role + cargo + permissions |
| **Mensagens / Chat** | `ChatScreen`, `ChatPrivadoScreen`, `ChatGrupoScreen` | Chat em tempo real + OTP |
| **Notificações** | `NotificacoesScreen` | Emitir exige `notification.create` |
| **Agenda** | `AgendaScreen`, `DetalheAgendaItemScreen`, `CriarReuniaoScreen`, `DetalheReuniaoScreen` | Compromissos colaborativos |
| **Equipas** | `EquipaScreen`, `EquipaScreenGestor`, `DetalheFuncionarioScreen` | Composição e visualização |
| **Perfil** | `ProfileScreen` | Dados do utilizador autenticado |
| **Super-Admin** | `SuperAdminTenantsScreen`, `SuperAdminTenantDetailScreen`, `SuperAdminPlanosScreen`, `SuperAdminPlanoFormScreen`, `SuperAdminTenantPlanoScreen`, `SuperAdminDashboardScreen` | Escopo de **plataforma** — não usa permissões de tenant |

**Aviso técnico do spec:** hoje `/notifications`, `/messages`, `/agenda`, `/uploads` e `/teams` exigem `ModuleHR`, o que é **semanticamente incorreto**. Será corrigido no backend — o mobile deve **não assumir** acesso via HR e preparar-se para módulos transversais próprios.

---

## 🚧 **ÁREAS DO SPEC AINDA NÃO COBERTAS NO MOBILE**

A spec v1.4 inclui domínios funcionais completos que **ainda não têm UI no mobile**. Não fazem parte dos 19 módulos de cargo, mas são candidatos naturais a evolução:

| Domínio (spec) | Estado backend | Prioridade mobile |
|----------------|----------------|-------------------|
| **Compras** (requisições, PO, aprovação, receção, avaliação fornecedores) | Tem | 📈 Média — cargo `purchasing` |
| **Stock / Armazéns / Inventário / Lotes-Séries / Validades** | Tem | 🔥 Alta — scanner + ajustes |
| **WMS** (configuração, sincronização) | Tem | 📈 Média (`wms.manage`, `wms.sync`) |
| **Transportes** (frota, motoristas, rotas, viagens) | Tem | 📈 Média — GPS + POD |
| **Financeiro** (tesouraria, caixa, bancos, AP/AR, reconciliação, cash flow, orçamentos, cobranças) | Tem | 🔥 Alta (dashboards) / 📈 Média (escrita) |
| **Contabilidade** (plano de contas, lançamentos, diário, razão, balancete, fecho, centros de custo, DRE+Balanço v1.4, Fecho Anual v1.4) | Tem | 📉 Baixa — mobile mais para consulta |
| **Produção** (ordens fabrico, planeamento, QC, manutenção, ativos) v1.4 | Tem | 📉 Baixa — depende do segmento |
| **Projetos e Serviços** v1.4 (tarefas, timesheets, SLA, ordens de serviço) | Tem | 📈 Média — timesheets mobile |
| **Gestão Documental** v1.4 (classificação, pastas, retenção, versionamento) | Tem | 📈 Média |
| **Workflow Engine** v1.4 | Tem | 📈 Média — aprovações mobile |
| **Integrações externas** v1.4 (banking, fiscal, e-commerce, POS) | Tem | 📉 Baixa — back-office |
| **Multi-moeda / Multi-idioma** v1.4 | Tem | 🔥 Alta (i18n) / 📈 Média (moeda) |
| **BI avançado** v1.4 (KPIs, metas, snapshots, projeção) | Tem | 🔥 Alta — dashboards |
| **Customer Success Engine** v1.4 (jornadas, snapshots, forecast) | Tem | 📈 Média — gestor |
| **Recrutamento** (integração) | Tem | 📉 Baixa |

Para detalhe das prioridades originais ver **"Lacunas e prioridades" P1/P2/P3** em [spec.md](../../backend/docs/spec.md).

---

## 🎯 **ROADMAP DE COBERTURA MOBILE**

### **Fase 1 — Consolidar os 19 módulos de cargo existentes (8 semanas)**

Focar em transformar as listagens em CRUD operacional completo com respeito às permissões.

1. **Sem 1-2:** Clientes + Produtos (CRUD + scanner)
2. **Sem 3-4:** Cotações + Encomendas (criação, aprovação, conversão)
3. **Sem 5-6:** Faturas + Recibos + Notas de crédito (emissão + anulação)
4. **Sem 7-8:** Entregas + Devoluções (POD, fluxo de regularização)

### **Fase 2 — RH completo, CRM operacional, Relatórios (6 semanas)**

1. **Sem 9-10:** RH — contratos, documentos, formação
2. **Sem 11-12:** CRM — criação de leads/deals/atividades + campanhas
3. **Sem 13-14:** Relatórios + Dashboard executivo

### **Fase 3 — Estender para domínios do spec fora dos módulos de cargo (ordem P1→P3)**

1. **Stock / Inventário / Armazéns** (P2 do spec)
2. **Financeiro leve** (consulta de tesouraria, cobranças) (P1 do spec)
3. **Transportes mobile** (GPS + POD) (P2 do spec)
4. **Workflow e Gestão documental** mobile (P2 do spec)
5. **Produção e Projetos** (v1.4 — conforme segmento de tenant)

### **Fase 4 — Hardening transversal (4 semanas)**

1. **i18n** (multi-idioma — v1.4 do spec)
2. **Multi-moeda** em documentos comerciais
3. **Permissões granulares** (`own`/`dept`/`all`) aplicadas na UI
4. **Testing, QA e performance**

---

## ✅ **CONCLUSÃO**

### **Estado atual**
- ✅ **19 módulos** de cargo do spec têm tela dedicada no mobile
- ✅ **Assiduidade** (RH) é o fluxo mais maduro — múltiplos métodos de registo
- ✅ **Super-admin** já tem navegação de tenants e planos
- ✅ Login, tokens e navegação por role funcionam
- ⚠️ Maioria dos módulos operacionais em **listagem básica** — sem CRUD completo
- ❌ **Enforcement** de permissões na UI ainda reativo (depende do 403 da API)
- ❌ **Domínios alargados do spec** (compras, finanças, contabilidade, produção, projetos) sem cobertura mobile

### **Principais lacunas face à spec v1.4**
1. **Permissões operacionais na UI** — esconder/desabilitar por `permissions` do login
2. **CRUD completo dos 19 módulos** — não apenas listagens
3. **Fluxo comercial ponta-a-ponta** — hoje fragmentado por tela
4. **Domínios v1.4** (Gestão Documental, Workflow, Produção, Projetos, BI avançado, Customer Success, i18n, multi-moeda) — sem UI mobile
5. **Novos módulos de cargo** — Compras, Stock/WMS, Transportes, Financeiro detalhado

### **Próximos passos imediatos**
1. Consumir `permissions` do `/auth/login` e aplicar guards na UI
2. Trocar listagens estáticas por **CRUD** completo nos 19 módulos
3. Implementar **formulários** de criação/edição por permissão
4. Integrar **filtros, busca e paginação** alinhadas com o backend
5. Respeitar **permissões granulares** (`own`/`dept`/`all`) quando o backend as aplicar

**Resultado esperado:** app mobile com **19 módulos operacionais funcionais** (CRUD), base sólida para expansão aos restantes domínios do spec v1.4.

---

*Análise alinhada com `backend/docs/spec.md` v1.4 (2026-04-24).*
