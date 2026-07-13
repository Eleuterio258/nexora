# 📱 LACUNAS FUNCIONAIS — App Mobile OmniSysERP

> **Referência canónica:** [backend/docs/spec.md v1.4](../../backend/docs/spec.md)
> **Data:** 2026-04-24
> **Framework:** React Native + Expo SDK 54 / React Native 0.81 / React Navigation 7
> **Escopo:** lacunas totais do mobile face à especificação funcional, cobrindo os 19 módulos operacionais do spec, os 3 escopos de role (super-admin / gestor / funcionário) e os domínios transversais (auth, permissões, offline, i18n, multi-moeda).

---

## 🎯 CONTEXTO

O app cobre hoje:
- **Assiduidade madura** do lado funcionário (5 métodos)
- **Dashboard + equipa + ausências** do lado gestor
- **Tenants + planos** do lado super-admin
- **19 módulos ERP** como telas de listagem em `screens/modules/` (CRUD por fazer)
- **Navegação, tema claro/escuro, componentes partilhados**

A spec v1.4 exige muito mais que assiduidade — é um ERP multi-tenant completo. Este documento lista as lacunas **em todos os domínios**, não apenas no fluxo de presenças.

---

## ✅ O QUE JÁ ESTÁ IMPLEMENTADO

### 📊 **Funcionário (tema claro)**
- ✅ Login, recuperação de password
- ✅ Assiduidade: 5 métodos (Face, QR, NFC, Selfie+GPS, PIN)
- ✅ Histórico, justificativas, perfil
- ✅ Férias: solicitar e acompanhar pedidos
- ✅ Agenda e reuniões
- ✅ Chat privado e em grupo
- ✅ Notificações
- ✅ Hub de módulos ERP

### 👨‍💼 **Gestor (tema escuro)**
- ✅ Dashboard com WebSocket "live"
- ✅ Equipa, detalhe funcionário, pedidos de férias
- ✅ Registo manual, ocorrências, alertas
- ✅ Relatórios (visualização)
- ✅ CRM (visualização)
- ✅ Dispositivos, métodos, geofencing
- ✅ Acesso aos 19 módulos ERP (ModulosGestaoScreen)

### 🛠️ **Super Admin**
- ✅ Dashboard da plataforma
- ✅ Tenants (lista, detalhe)
- ✅ Planos (lista, formulário, associação tenant-plano)

### 🎨 **Design System**
- ✅ Tema dual (claro/escuro)
- ✅ Componentes reutilizáveis
- ✅ Stack + Bottom tabs
- ✅ Responsivo

### 📦 **Integrações Técnicas**
- ✅ Expo SDK 54, React Native 0.81, React Navigation 7
- ✅ `AsyncStorage` local
- ✅ Câmera, GPS, NFC (SDK disponível, integração real em falta)

---

## ❌ O QUE ESTÁ FALTANDO

As lacunas abaixo usam a prioridade **P1/P2/P3 do spec** ("Lacunas e prioridades"):

- **P1 — Alta:** bloqueia operação para casos de uso centrais; curto prazo
- **P2 — Média:** necessária para completude funcional; médio prazo
- **P3 — Baixa:** relevante para segmentos específicos ou maturidade avançada

---

## 🔴 P1 — CRÍTICO

### 1. Integração Real com Backend (contrato do spec)

**Status:** ❌ Dados mock na maioria das telas.

**Spec:** `POST /auth/login` retorna `{ token, user, tenant, role, cargo, permissions }`. Todas as chamadas seguintes enviam `Authorization: Bearer <token>`.

**Falta:**
- `AsyncStorage` completo com `role`, `cargo`, `permissions`, `tenant`
- Interceptor Axios com refresh token (`/auth/refresh`)
- Tratamento uniforme de 401 (logout) e 403 (esconder ação)
- Resolução do contexto de tenant em cada request
- Cache de leitura inteligente e TTL por domínio

### 2. Enforcement de Permissões na UI (4 camadas do spec)

**Status:** ❌ UI não verifica `permissions`; depende do 403 da API para bloquear.

**Spec (4 camadas):** autenticação → escopo de sistema → `admin.tenant` → módulo + permissão.

**Falta:**
- Helper `hasPermission(perm)` / `hasAnyPermission(...)` baseado no login
- Guards em rotas (`MODULE_ROUTE_CONFIGS`) por módulo
- Botões/menus escondidos conforme permissões (`quote.approve`, `invoice.void`, `payroll.approve`, `settings.manage`, ...)
- Bloqueio do super-admin em módulos operacionais do tenant (regra estrita do spec)
- Pipeline consistente para as **57 permissões** do spec

### 3. CRUD Completo nos 19 Módulos de Cargo

**Status:** ⚠️ Apenas listagens vindas da API.

**Spec (19 módulos):** `dashboard`, `sales`, `categories`, `products`, `customers`, `series`, `crm`, `payroll`, `hr`, `signatures`, `quotes`, `orders`, `deliveries`, `invoices`, `receipts`, `credit-notes`, `returns`, `reports`, `settings`.

**Falta (por módulo):**

| Módulo | Lacunas |
|--------|---------|
| `customers` | formulário, detalhe, histórico; bloqueio de eliminação com docs ativos |
| `products` | scanner código de barras, variantes, fotos, stock por armazém |
| `categories` | árvore hierárquica, drag-drop |
| `series` | configuração de sequências, ativação/desativação |
| `quotes` | criação, aprovação (**separada**), conversão em encomenda |
| `orders` | criação, aprovação, cancelamento, alerta de devolução |
| `deliveries` | geração, POD (foto + assinatura), confirmação → sync WMS |
| `invoices` | emissão, PDF viewer, anulação com NC |
| `receipts` | registo, métodos de pagamento, anulação |
| `credit-notes` | emissão ligada a fatura |
| `returns` | registo, aprovação, geração automática de NC e stock |
| `hr` | CRUD funcionário, contratos, documentos, formação |
| `payroll` | processamento, aprovação, recibos PDF, simulação |
| `crm` | criação de leads/deals/atividades, campanhas, tickets |
| `signatures` | criação de documento, captura de assinatura, envio, OTP |
| `reports` | gráficos, filtros, exportação (`report.export`) |
| `dashboard` | drill-down, filtros por período |
| `settings` | escrita (`settings.manage`) |

### 4. Fluxo Comercial Ponta-a-Ponta

**Status:** ❌ Fragmentado por tela.

**Spec:** progressão `Proposta → Pedido → Entrega → Faturação → Recebimento → (Notas de crédito / Devoluções)`.

**Falta:**
- Navegação inter-módulo (cotação → encomenda → entrega → fatura → recibo)
- Contextos e regras: cotação aprovada vira encomenda; encomenda com entrega exige devolução para cancelar; fatura anulada pode exigir NC
- Série documental selecionada dinamicamente conforme tipo

### 5. Biometria Facial Funcional

**Status:** ❌ UI apenas; câmera e face detection não ligadas.

**Falta:**
- Integração `expo-camera` + `expo-face-detector`
- Liveness detection (olhos abertos, blink, ângulo facial)
- Envio para `POST /api/hr/attendance/events` conforme spec (evento + método `face`)
- Armazenamento seguro dos vetores (device enrollment)

### 6. GPS + Geofencing Real

**Status:** ⚠️ Básico — sem validação real de perímetro.

**Falta:**
- `expo-location` com alta precisão
- Geofence dinâmico vindo do tenant (`settings`)
- Distância Haversine vs. pontos permitidos
- Detecção de GPS spoofing (precisão, saltos)
- Cache offline da última localização válida

### 7. Push Notifications (módulo `notifications` do spec)

**Status:** ❌ Mock.

**Spec:** emitir exige `notification.create`; receber é livre.

**Falta:**
- `expo-notifications` + Expo push token
- Registo `POST /users/register-device`
- Handlers para tipos: `leave_approved`, `quote_approved`, `delivery_assigned`, `attendance_reminder`, `invoice_overdue`
- Background tasks para sync quando notificação chega

### 8. Lacunas Técnicas do Backend (spec — "Lacunas técnicas")

**Status (backend):** permissões sem constante, rotas sem guard, `payroll.process` colapsado em `approve`, `ModuleHR` carregando domínios transversais.

**Implicações no mobile:**
- Não presumir enforcement — validar reativamente
- Preparar UI para separação de `payroll.process` vs. `payroll.approve`
- Notificações, mensagens, agenda, uploads, equipas **sem exigir** `ModuleHR` (correção futura do backend)

---

## 🟡 P2 — IMPORTANTE

### 9. Offline Mode Seletivo + Sync

**Status:** ⚠️ `AsyncStorage` apenas.

**Política recomendada (alinhada com spec):**
- **Permitido offline:** assiduidade, ausências, atividades CRM, confirmação de entrega (POD)
- **Bloqueado offline:** financeiro (faturas, recibos, NC, devoluções) — integridade documental

**Falta:**
- Fila de ações (`offlineStorage`) com retry
- `SyncManager` baseado em `@react-native-community/netinfo`
- Conflict resolution (timestamp + versão)
- Indicadores offline na UI
- Background fetch (`expo-background-fetch`)

### 10. Permissões Granulares (`own` / `dept` / `all`)

**Status:** ❌ Não implementado.

**Spec:** o motor `CanAccessGranularPermission` já existe no backend; filtro de escopo em queries é responsabilidade de cada handler.

**Falta no mobile:**
- Consumir `GET /api/admin/usuarios/{id}/granular-permissions`
- Aplicar escopo nas listagens (`?scope=own|dept|all`)
- Condições contextuais (`purchase.approve.up_to_1000`) na UI
- Permissões temporárias com expiração

### 11. Módulos do Spec SEM UI Mobile (domínios alargados)

Estes não são "módulos de cargo" mas **áreas funcionais** do backend OmniSysERP sem cobertura mobile:

| Domínio (spec) | Estado backend | Ação mobile |
|----------------|----------------|-------------|
| **Compras** (requisições, PO, aprovação, receção, avaliação fornecedores) | Tem | Novo cargo `purchasing` + telas |
| **Stock / Armazéns / Inventário / Lotes-Séries / Validades** | Tem | Scanner + ajustes (`stock.view`, `stock.adjust`) |
| **WMS** (configuração, sincronização) | Tem | Ecrã de sync (`wms.manage`, `wms.sync`) |
| **Transportes** (frota, motoristas, rotas, viagens, POD) | Tem | Mobile motorista + GPS tracking |
| **Financeiro** (tesouraria, caixa, bancos, AP/AR, cash flow, orçamentos, cobranças, reconciliação) | Tem | Consulta mobile + cobranças |
| **Contabilidade** (plano contas, lançamentos, diário, razão, balancete, fecho, DRE+Balanço, fecho anual, centros custo) | Tem v1.4 | Consulta ligeira |
| **Produção** (ordens fabrico, planeamento, consumo, QC, manutenção, ativos) | Tem v1.4 | Dependente do segmento do tenant |
| **Projetos e Serviços** (tarefas, timesheets, SLA, ordens de serviço) | Tem v1.4 | Timesheets mobile |
| **Gestão Documental** (classificação, pastas, metadados, retenção, versionamento) | Tem v1.4 | Explorador documental |
| **Workflow Engine** | Tem v1.4 | Aprovações mobile |
| **Customer Success Engine** (jornadas, snapshots, forecast) | Tem v1.4 | Dashboards gestor |
| **Integrações externas** (banking, fiscal, e-commerce, POS) | Tem v1.4 | Dashboards + estado |
| **Recrutamento** (integração webhooks) | Tem | Dashboard de candidaturas |

### 12. Multi-idioma (i18n) — v1.4

**Status:** ❌ Não implementado no app.

**Spec v1.4:** backend já suporta.

**Falta:**
- `i18next` + `react-i18next` + `expo-localization`
- Catálogos PT / EN / FR alinhados com o backend
- Detecção automática do idioma do dispositivo
- Troca manual no `ProfileScreen`

### 13. Multi-moeda — v1.4

**Status:** ❌ Hard-coded.

**Spec v1.4:** backend suporta múltiplas moedas por transação e taxas de câmbio.

**Falta:**
- Moeda vinda do tenant / documento
- Formatação com `Intl.NumberFormat`
- Taxa de câmbio fetched on demand em documentos multi-moeda
- Indicadores visuais de moeda original vs. conversão

### 14. BI Avançado — v1.4 (KPIs, metas, snapshots, projeção)

**Status:** ❌ Dashboard em placeholder.

**Spec v1.4:** backend já expõe KPIs estruturados, metas e projeções.

**Falta no mobile:**
- Dashboards executivos por domínio
- Gráficos de série temporal (recharts / victory-native)
- Metas com semáforo (verde / amarelo / vermelho)
- Projeções comparativas

### 15. Notificações, Mensagens, Agenda, Uploads, Equipas como módulos transversais

**Status:** ⚠️ Telas existem mas backend ainda exige `ModuleHR` (erro semântico do spec).

**Falta:**
- Quando o backend corrigir: remover dependência de `ModuleHR`
- Módulo próprio para notificações internas
- Chat em tempo real via WebSocket
- Agenda partilhada com integração de reuniões

### 16. PIN / TOTP / QR Seguros

**Status:** ⚠️ Básico.

**Falta:**
- TOTP RFC 6238 para PIN (com provisioning por QR)
- QR Code **dinâmico por sessão** (expiração + location binding + anti-replay)
- PIN com regras de complexidade e proteção anti-brute-force
- Backup codes

### 17. NFC Funcional

**Status:** ❌ UI apenas.

**Falta:**
- `react-native-nfc-manager`
- Validação do UID do cartão no backend
- Anti-clone (data + nonce + assinatura)
- Compatibilidade com múltiplos leitores

### 18. Audit Trail Mobile

**Status:** ❌ Inexistente.

**Spec:** auditoria transversal (`audit_logs`) no backend.

**Falta:**
- Envio de eventos de UI para `audit_logs` (sem PII sensível)
- Device fingerprinting
- Tempo servidor-sincronizado (anti-drift)
- Dados forenses para investigação

### 19. Error Handling Uniforme

**Status:** ⚠️ Tratamento limitado.

**Falta:**
- Mensagens user-friendly por código (400/401/403/404/409/422/500)
- Ações de recuperação (retry, reautenticar, abrir ajuda)
- Validação server-side refletida em formulários
- Crash reporting (Sentry)

### 20. Loading e Skeleton States

**Status:** ⚠️ Inconsistente.

**Falta:**
- Skeleton loaders por tipo de tela (lista, detalhe, formulário)
- Progress indicators em uploads
- Error boundaries React
- Retry buttons nativos
- Indicadores offline persistentes

---

## 🟢 P3 — DESEJÁVEL

### 21. Multi-tenant UI (switching)

**Status:** ⚠️ Contexto único por sessão.

**Falta:**
- Troca de tenant sem logout
- Branding por tenant (cores, logo)
- Feature toggles conforme plano

### 22. Device Management

**Status:** ⚠️ Básico.

**Falta:**
- Registo de dispositivo + aprovação
- Remote wipe (em caso de perda)
- App lock por inatividade
- Compliance checks (jailbreak/root detection)

### 23. Analytics & Insights

**Status:** ❌ Inexistente.

**Falta:**
- Usage analytics (Amplitude / Mixpanel / PostHog)
- Crash reporting (Sentry)
- Performance monitoring (Firebase Performance)
- User behavior tracking (respeitando privacidade)

### 24. Accessibility

**Status:** ❌ Limitada.

**Falta:**
- Screen reader (`accessibilityLabel`, `accessibilityRole`)
- Contraste alto
- Font scaling
- Gesture alternatives
- Suporte a daltonismo (não depender só de cor)

### 25. Performance

**Status:** ⚠️ Aceitável.

**Otimizar:**
- `FlashList` em vez de `FlatList` em listas longas
- Memoização (`React.memo`, `useCallback`)
- Image optimization (`expo-image`)
- Bundle splitting
- Caching por domínio

### 26. Produção (v1.4) — mobile motorista de produção

**Status:** ❌ Sem UI.

**Dependência:** segmento industrial do tenant.

**Falta:**
- Consumo de ordem de fabrico
- Apontamento de QC
- Manutenção preventiva + corretiva mobile
- Inventário de ativos com scanner

### 27. Projetos e Serviços (v1.4) — timesheets mobile

**Status:** ❌ Sem UI.

**Falta:**
- Lançamento de horas por projeto/tarefa
- SLA awareness em ordens de serviço
- Ordem de serviço mobile (técnicos de campo)

### 28. Gestão Documental (v1.4)

**Status:** ❌ Sem UI.

**Falta:**
- Explorador de pastas e documentos
- Pesquisa por metadados
- Versionamento visível
- Retenção e arquivamento

### 29. Workflow Engine (v1.4) — aprovações mobile

**Status:** ❌ Sem UI.

**Falta:**
- Inbox de aprovações pendentes
- Caminho do fluxo visível
- Aprovação/rejeição com comentário
- Histórico de decisões

---

## 🛠️ **PACOTES NPM ADICIONAIS NECESSÁRIOS**

```bash
# Networking + offline
npm install axios @react-native-community/netinfo

# Permissões e acesso
# (sem lib externa — helpers em src/access/)

# Câmera + biometria
npx expo install expo-camera expo-face-detector

# GPS
npx expo install expo-location

# NFC
npm install react-native-nfc-manager

# Push + background
npx expo install expo-notifications expo-device expo-background-fetch expo-task-manager

# i18n
npm install i18next react-i18next
npx expo install expo-localization

# Gráficos
npm install victory-native  # ou recharts-native

# Performance
npm install @shopify/flash-list
npx expo install expo-image

# Crash + analytics
npm install @sentry/react-native
npm install posthog-react-native  # ou amplitude-react-native

# Signature pad (signatures module)
npm install react-native-signature-canvas
```

---

## 📋 **ROADMAP DE RESOLUÇÃO**

Alinhado com `GUIA_IMPLEMENTACAO_PRACTICA.md` e prioridades do spec.

### 🔴 Sprint 1 (Sem 1-2) — Fundações P1
1. Integração real com backend + contrato do spec
2. Guards de permissão em UI (`hasPermission`)
3. Handler uniforme de erros (401/403/...)
4. Refresh token flow

### 🔴 Sprint 2 (Sem 3-4) — RH P1
5. Biometria facial real + liveness
6. GPS + geofencing real + spoofing detection
7. NFC funcional com anti-clone
8. Push notifications (módulo `notifications`)

### 🔴 Sprint 3 (Sem 5-6) — Fluxo Comercial P1
9. CRUD `customers`, `quotes`, `orders`, `deliveries`
10. POD em entregas (foto + assinatura)
11. Conversão cotação→encomenda

### 🔴 Sprint 4 (Sem 7-8) — Faturação P1
12. CRUD `invoices`, `receipts`, `credit-notes`, `returns`
13. Séries documentais (`series.manage`)
14. PDF viewer de documentos

### 🟡 Sprint 5 (Sem 9-10) — Demais módulos P1/P2
15. `crm` com criação de leads/deals/atividades
16. `payroll` (processamento + aprovação separados)
17. `signatures` com signature pad + OTP
18. `reports` com exportação
19. `dashboard` com drill-down
20. `settings` com escrita

### 🟡 Sprint 6 (Sem 11-12) — Transversais P2
21. Offline seletivo + sync manager
22. Permissões granulares (`own`/`dept`/`all`)
23. i18n (PT/EN/FR)
24. Multi-moeda
25. Audit trail mobile
26. Error handling + skeleton states

### 🟢 Sprint 7 (Sem 13-14) — Domínios v1.4 e polimento P3
27. Stock/Inventário/WMS mobile
28. Transportes (motorista mobile)
29. Workflow Engine (inbox de aprovações)
30. Gestão Documental
31. BI avançado (KPIs)
32. Multi-tenant switching
33. Accessibility + performance
34. Analytics + crash reporting

### 🟢 Sprint 8+ (dependente do segmento)
35. Produção mobile
36. Projetos/timesheets
37. Customer Success dashboards
38. Device management

---

## 🎯 **MÉTRICAS DE SUCESSO**

### Alinhadas com regras do spec
- ✅ **100% dos módulos de cargo** com CRUD (19/19)
- ✅ **100% das permissões do spec** enforcement na UI (57 permissões)
- ✅ **4 camadas** de autorização respeitadas
- ✅ **Fluxo comercial** ponta-a-ponta funcional
- ✅ **`payroll.process` ≠ `payroll.approve`** quando o backend separar
- ✅ **Super-admin** bloqueado fora do escopo de plataforma

### Qualidade
- ✅ <2s load time por tela
- ✅ <5% crash rate
- ✅ 99% uptime da integração
- ✅ 95% accuracy biometria
- ✅ <100MB memória em uso normal
- ✅ 4.5+ stars App Store / Play Store

---

## 💡 **CONCLUSÃO**

O app mobile tem **base sólida** (41+ telas, 3 personas, 19 módulos ERP mapeados) mas precisa de **três camadas críticas** antes de produção:

1. **Contrato de backend real** alinhado com `backend/docs/spec.md` v1.4
2. **Enforcement de permissões** na UI (4 camadas do spec + 57 permissões)
3. **CRUD operacional completo** nos 19 módulos (hoje listagens)

Depois, os **domínios v1.4 do spec** (Compras, Stock/WMS, Transportes, Financeiro, Gestão Documental, Workflow, BI avançado, Produção, Projetos, Customer Success, i18n, multi-moeda) abrem o próximo horizonte.

**Foco imediato:** completar Sprints 1-4 (Sem 1-8) para ter o app **production-ready** com os 19 módulos operacionais e assiduidade real. O restante é evolução modular.

---

*Análise alinhada com `backend/docs/spec.md` v1.4 (2026-04-24) — ver também `ANALISE_MODULOS_MOBILE.md` e `GUIA_IMPLEMENTACAO_PRACTICA.md`.*
