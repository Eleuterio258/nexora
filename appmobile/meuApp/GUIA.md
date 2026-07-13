# Guia Rápido — App Mobile OmniSysERP

> **Referência funcional:** [backend/docs/spec.md v1.4](../../backend/docs/spec.md)
> **Data:** 2026-04-24
> **Escopo:** mobile multi-persona (super-admin, gestor, funcionário) sobre o backend OmniSysERP

Este app é a interface mobile do **OmniSysERP** — ERP multi-tenant definido em `backend/docs/spec.md`. Cobre os 19 módulos operacionais de cargo, o escopo de plataforma (super-admin) e o fluxo de assiduidade/pessoas do lado do colaborador.

## 🚀 Como Executar

```bash
cd D:\projecto\u-tech\2026\omnisyserp\appmobile\meuApp
npm start
```

Depois:
- Pressione **a** para Android
- Pressione **i** para iOS
- Ou escaneie o QR code com a app Expo Go

## 🧭 Modelo de acesso (alinhado com spec)

O backend aplica controlo de acesso em **quatro camadas**:
1. Autenticação (JWT)
2. Escopo de sistema (`super-admin`)
3. Escopo de administração do tenant (`admin.tenant`)
4. Escopo de módulo e permissão (`invoice.create`, `quote.approve`, ...)

### Roles globais válidos (spec)

| Role | Alias | Escopo | App |
|------|-------|--------|-----|
| `super-admin` | `super_admin` | Plataforma | Fluxo Super-Admin |
| `funcionario` | — | Tenant | Fluxo Funcionário / Gestor (conforme cargo) |

O perfil funcional real do `funcionario` é determinado pelo **cargo** atribuído no tenant.

## 📱 Fluxo de Navegação

### 1. Super-Admin (escopo de plataforma)

Reservado a `super-admin` — **sem acesso operacional** a módulos do tenant (regra estrita do spec).

```
Login (LoginScreen)
  ↓
SuperAdminDashboard
  ├─→ Tenants (SuperAdminTenantsScreen)
  │     └─→ Detalhe (SuperAdminTenantDetailScreen)
  │           └─→ Associar Plano (SuperAdminTenantPlanoScreen)
  └─→ Planos (SuperAdminPlanosScreen)
        └─→ Plano Form (SuperAdminPlanoFormScreen)
```

### 2. Funcionário — Assiduidade e Colaboração (Tema Claro)

Cobre **RH — Assiduidade e Ausências** do spec, mais mensagens/agenda/notificações/perfil. Navegação principal:

```
Login → HomeFuncScreen
  │
  ├─→ Registo de presença (método conforme `attendance` do tenant)
  │     ├─ Biometria Facial (FaceScreen)
  │     ├─ NFC (NFCScreen)
  │     ├─ QR Code (QRCodeScreen)
  │     ├─ Selfie + GPS (SelfieGPSScreen)
  │     └─ PIN/OTP (PINScreen)
  │           └─→ Success (SuccessScreen)
  │                 └─→ Histórico (HistoricoScreen)
  │                       └─→ Justificar (JustificarScreen)
  │
  ├─→ Ausências
  │     ├─ Solicitar Férias (SolicitarFeriasScreen / SolicitarFeriasFormScreen)
  │     └─ Detalhe Pedido (DetalhePedidoScreen)
  │
  ├─→ Agenda
  │     ├─ Criar Reunião (CriarReuniaoScreen)
  │     ├─ Detalhe Reunião (DetalheReuniaoScreen)
  │     └─ Detalhe Item (DetalheAgendaItemScreen)
  │
  ├─→ Chat / Mensagens (ChatScreen, ChatPrivadoScreen, ChatGrupoScreen)
  ├─→ Notificações (NotificacoesScreen)
  ├─→ Perfil (ProfileScreen)
  └─→ Hub de Módulos ERP (ModulesHubScreen)
        └─→ Detalhe do módulo (ModuleDetailScreen)
              → renderiza a tela operacional via MODULE_SCREEN_COMPONENTS
```

### 3. Gestor / Módulos Operacionais (Tema Escuro)

Ativa quando o cargo do funcionário inclui `dashboard` + módulos operacionais adicionais conforme a spec.

```
DashboardScreenGestor  (módulo: dashboard)
  ├─→ Equipa (EquipaScreenGestor)
  │     └─→ Detalhe Funcionário (DetalheFuncionarioScreen)
  ├─→ Pedidos de Férias (PedidoFeriasScreen)   — exige leave.approve
  ├─→ Registo Manual (RegistarManualScreen)    — exige attendance.manage
  ├─→ Ocorrências (OcorrenciasScreen)
  ├─→ Alertas (AlertasScreen)
  ├─→ Relatórios (RelatoriosScreenGestor)      — exige report.view
  ├─→ CRM (CRMScreen)                          — módulo crm
  ├─→ Módulos ERP (ModulosGestaoScreen → ModulesHubScreen)
  └─→ Mais (MaisScreen)
        ├─ Dispositivos
        ├─ Configuração de métodos de assiduidade
        └─ Geofencing
```

### 4. Hub de Módulos Operacionais (19 módulos do spec)

Acessível a partir do funcionário ou gestor, renderizado por `ModulesHubScreen` + `ModuleDetailScreen`. Cada tela corresponde a um **módulo de cargo** do spec:

| Domínio | Módulos (spec) | Telas |
|---------|----------------|-------|
| Comercial | `sales`, `quotes`, `orders`, `deliveries`, `customers` | Module{Sales,Quotes,Orders,Deliveries,Customers}Screen |
| Catálogo | `products`, `categories`, `series` | Module{Products,Categories,Series}Screen |
| Faturação | `invoices`, `receipts`, `credit-notes`, `returns` | Module{Invoices,Receipts,CreditNotes,Returns}Screen |
| Pessoas | `hr`, `payroll`, `crm` | Module{HR,Payroll,CRM}Screen |
| Documental | `signatures` | ModuleSignaturesScreen |
| Gestão | `dashboard`, `reports`, `settings` | Module{Dashboard,Reports,Settings}Screen |

As permissões específicas que habilitam ações em cada módulo (`quote.approve`, `invoice.void`, `payroll.approve`, etc.) vêm de `permissions` na resposta do `/auth/login`.

## 🔐 Autenticação e contexto

O login segue o fluxo do spec:

```
POST /auth/login  { email, password }
     │
     └─ 200 OK  { token, user, tenant, role, cargo, permissions }
```

O app armazena `token`, `user`, `tenant`, `cargo` e `permissions` em `AsyncStorage` e envia `Authorization: Bearer <token>` em todas as chamadas subsequentes. Respostas **401** despoletam logout; **403** deve esconder a ação na UI.

## 🧪 Testar Durante Desenvolvimento

Para testar diferentes fluxos durante o desenvolvimento, pode alterar o `initialRouteName` no arquivo `App.js`:

```javascript
// Testar app funcionário
<Stack.Navigator initialRouteName="Login" ...>

// Testar app gestor
<Stack.Navigator initialRouteName="DashboardGestor" ...>

// Testar super-admin
<Stack.Navigator initialRouteName="SuperAdminDashboard" ...>

// Testar tela específica
<Stack.Navigator initialRouteName="Face" ...>
```

## 🎨 Cores Utilizadas

### App Funcionário (Tema Claro)
- **Principal**: `#1A1A1A` (Preto)
- **Sucesso**: `#1D9E75` (Verde)
- **Erro/Alerta**: `#E24B4A` (Vermelho)
- **Aviso**: `#BA7517` (Âmbar)
- **Info**: `#378ADD` (Azul)
- **Background**: `#FFFFFF` (Branco)
- **Card**: `#F5F5F5` (Cinza claro)

### App Gestor / Super-Admin (Tema Escuro)
- **Background**: `#0f1117`
- **Surface**: `#171b24`
- **Surface 2**: `#1e2330`
- **Texto**: `#e8eaf0`
- **Muted**: `#6b7280`
- **Verde (Sucesso)**: `#1fd898`
- **Vermelho (Erro)**: `#ff5c6a`
- **Âmbar (Aviso)**: `#f5a623`
- **Azul (Info)**: `#4e8ef7`
- **Accent**: `#1fd898`

## 📝 Notas Importantes

1. **Multi-persona** — `super-admin`, `gestor`, `funcionario` são visualizados como três fluxos distintos conforme o spec
2. **Multi-tenant** — o contexto do tenant é resolvido no login e propagado em cada chamada
3. **Permissões reativas** — a UI esconde/desabilita ações conforme `permissions` do `/auth/login`
4. **Assiduidade** é o fluxo mais maduro — múltiplos métodos conforme config do tenant
5. **Lacunas técnicas conhecidas** (spec — "Lacunas técnicas de implementação"): algumas permissões ainda não estão implementadas como constantes no backend; o mobile deve validar reativamente pelos códigos HTTP da API e preparar-se para as correções futuras

## 🔧 Próximos Passos

1. **Aplicar guards de permissão** em cada ação de UI conforme `permissions` do login
2. **CRUD completo** nos 19 módulos (hoje maioritariamente listagens)
3. **Integração WMS** (`wms.manage`, `wms.sync`) e **Stock/Inventário** (`stock.view`, `stock.adjust`)
4. **Permissões granulares** — consumir `/api/admin/usuarios/{id}/granular-permissions` e respeitar escopo `own`/`dept`/`all`
5. **Domínios v1.4 do spec** — cobertura mobile progressiva de Compras, Financeiro, Transportes, Gestão Documental, Workflow, BI avançado, Produção e Projetos (ver `ANALISE_MODULOS_MOBILE.md`)
6. **i18n** e **multi-moeda** (v1.4 já no backend)
7. **Offline + sync** resiliente para fluxos de campo (assiduidade, entregas, visitas CRM)
8. **Push notifications** integradas com `notifications` do spec (emitir exige `notification.create`)

## 📂 Arquivos Principais

- `App.js` — configuração completa da navegação (funcionário + gestor + super-admin + módulos)
- `screens/funcionario/` — fluxo de colaborador (assiduidade, ausências, chat, agenda, perfil)
- `screens/gestor/` — fluxo de gestão (dashboard, equipa, pedidos, relatórios)
- `screens/superadmin/` — escopo de plataforma (tenants, planos)
- `screens/modules/` — 19 módulos operacionais do spec
- `screens/shared/` — hubs e componentes partilhados (`ModulesHubScreen`, `ModuleDetailScreen`)
- `src/access/` — configurações de rota por módulo/permissão
- `src/theme/` — tema claro/escuro
- `ANALISE_MODULOS_MOBILE.md` — estado detalhado por módulo vs. spec
- `GUIA_IMPLEMENTACAO_PRACTICA.md` — plano prático de evolução

## ✨ Funcionalidades Atuais

### Super-Admin
✅ Dashboard, tenants e planos
✅ Atribuição de plano a tenant
⚠️ Apenas leitura detalhada — sem escrita operacional

### Funcionário (Tema Claro)
✅ Login e recuperação de password
✅ **Assiduidade completa** — biometria, NFC, QR, Selfie+GPS, PIN/OTP
✅ Histórico de registos e justificações
✅ Pedidos de férias / ausências
✅ Agenda / reuniões
✅ Chat (privado e grupo) + notificações
✅ Perfil e hub de módulos

### Gestor (Tema Escuro)
✅ Dashboard com WebSocket "live"
✅ Equipa, detalhe funcionário, pedidos de férias
✅ Registo manual de assiduidade
✅ Ocorrências e alertas
✅ Relatórios (consulta)
✅ CRM (visualização)
✅ Dispositivos, métodos, geofencing
✅ Hub completo dos 19 módulos operacionais

### Módulos Operacionais ERP (19)
⚠️ Todos têm tela e consumo de API de listagem — CRUD, formulários e fluxos avançados em implementação (ver `ANALISE_MODULOS_MOBILE.md`)

## 🆘 Resolução de Problemas

### Erro: "Module not found"
```bash
npm install
```

### Erro de navegação
```bash
npm install @react-navigation/native @react-navigation/native-stack react-native-screens react-native-safe-area-context
```

### Limpar cache e reiniciar
```bash
npm start -- --clear
```

### Erro 401 inesperado
Token expirado — o app deve fazer logout. Verifique o interceptor em `src/api/client.js` e a renovação via `/auth/refresh`.

### Erro 403 em ações
O cargo atual não tem a permissão necessária (ex: `quote.approve`, `invoice.void`). Consulte `permissions` do login e ajuste a UI para esconder a ação.

## 📞 Suporte

- [backend/docs/spec.md](../../backend/docs/spec.md) — referência funcional canónica
- [ANALISE_MODULOS_MOBILE.md](./ANALISE_MODULOS_MOBILE.md) — estado de cada módulo vs. spec
- [GUIA_IMPLEMENTACAO_PRACTICA.md](./GUIA_IMPLEMENTACAO_PRACTICA.md) — plano de evolução
- React Navigation: https://reactnavigation.org
- Expo: https://docs.expo.dev

---

*Alinhado com `backend/docs/spec.md` v1.4 (2026-04-24).*
