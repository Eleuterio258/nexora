# 🛠️ GUIA IMPLEMENTAÇÃO — App Mobile OmniSysERP

> **Referência canónica:** [backend/docs/spec.md v1.4](../../backend/docs/spec.md)
> **Data:** 2026-04-24
> **Escopo:** plano prático de evolução do app mobile para cobrir os 19 módulos operacionais do spec e respeitar o contrato de autenticação, autorização e permissões.

---

## 🎯 **OBJETIVO**

Transformar o app — hoje com assiduidade madura, navegação super-admin/gestor/funcionário e 19 módulos ERP em listagem — numa **solução production-ready** alinhada com `backend/docs/spec.md` v1.4.

**Prazo:** 10 semanas (5 sprints)
**Prioridade:** CRÍTICA
**Data início:** Maio 2026

### Linhas mestras alinhadas com o spec
- **Autenticação JWT** com resposta `{ token, user, tenant, role, cargo, permissions }`
- **Autorização em 4 camadas**: role → `admin.tenant` → módulo → permissão
- **Módulos de cargo** (19): `dashboard`, `sales`, `categories`, `products`, `customers`, `series`, `crm`, `payroll`, `hr`, `signatures`, `quotes`, `orders`, `deliveries`, `invoices`, `receipts`, `credit-notes`, `returns`, `reports`, `settings`
- **Permissões granulares** com escopo `own`/`dept`/`all` e condições contextuais
- **Multi-tenant** — contexto resolvido no login e propagado em todas as chamadas

---

## 🔥 **SPRINT 1 (Sem 1-2): BACKEND INTEGRATION + AUTORIZAÇÃO**

### Dia 1-2: API Client + Contrato do spec
**Objetivo:** Conectar app com API real respeitando o fluxo de auth do spec.

**Arquivos a modificar:**
- `src/config.js` — URLs produção
- `src/api/client.js` — interceptors
- `src/access/` — extensão do sistema de permissões
- `screens/funcionario/LoginScreen.js` — login real

**Implementação:**
```javascript
// src/api/client.js
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

const apiClient = axios.create({
  baseURL: process.env.EXPO_PUBLIC_API_URL || 'https://api.omnisyserp.com/api',
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
});

apiClient.interceptors.request.use(async (config) => {
  const token = await AsyncStorage.getItem('authToken');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      const refreshToken = await AsyncStorage.getItem('refreshToken');
      if (refreshToken) {
        try {
          const r = await axios.post('/auth/refresh', { refreshToken });
          await AsyncStorage.setItem('authToken', r.data.token);
          error.config.headers.Authorization = `Bearer ${r.data.token}`;
          return apiClient.request(error.config);
        } catch (_) {
          await AsyncStorage.multiRemove(['authToken', 'refreshToken', 'userData', 'permissions']);
        }
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### Dia 3: Login real alinhado com spec

O `/auth/login` do spec retorna `{ token, user, tenant, role, cargo, permissions }`. Armazenar tudo e guiar a navegação por `role`:

```javascript
// screens/funcionario/LoginScreen.js
const handleLogin = async () => {
  const r = await apiClient.post('/auth/login', { email, password });
  const { token, refreshToken, user, tenant, role, cargo, permissions } = r.data;

  await AsyncStorage.multiSet([
    ['authToken', token],
    ['refreshToken', refreshToken ?? ''],
    ['userData', JSON.stringify(user)],
    ['tenant', JSON.stringify(tenant)],
    ['role', role],
    ['cargo', JSON.stringify(cargo)],
    ['permissions', JSON.stringify(permissions || [])],
  ]);

  if (role === 'super-admin' || role === 'super_admin') {
    navigation.replace('SuperAdminDashboard');
  } else {
    const modules = cargo?.modules || [];
    navigation.replace(modules.includes('dashboard') ? 'DashboardGestor' : 'HomeFunc');
  }
};
```

### Dia 4: Guards de permissão reutilizáveis

```javascript
// src/access/permissions.js
import AsyncStorage from '@react-native-async-storage/async-storage';

let cache = null;

export const loadPermissions = async () => {
  if (cache) return cache;
  const raw = await AsyncStorage.getItem('permissions');
  cache = raw ? JSON.parse(raw) : [];
  return cache;
};

export const hasPermission = async (perm) => (await loadPermissions()).includes(perm);

export const hasAnyPermission = async (...perms) => {
  const have = await loadPermissions();
  return perms.some((p) => have.includes(p));
};

export const resetPermissionsCache = () => { cache = null; };
```

```javascript
// Exemplo de uso — esconder botão sem permissão
const [canApprove, setCanApprove] = useState(false);
useEffect(() => { hasPermission('quote.approve').then(setCanApprove); }, []);
{canApprove && <Button title="Aprovar" onPress={onApprove} />}
```

### Dia 5: Handler de erros alinhado com o contrato

```javascript
// src/utils/errorHandler.js
export const handleApiError = (error, navigation) => {
  if (!error.response) return 'Erro de conexão. Verifique a internet.';
  const { status, data } = error.response;
  switch (status) {
    case 400: return data?.message || 'Dados inválidos.';
    case 401:
      navigation.replace('Login');
      return 'Sessão expirada. Faça login novamente.';
    case 403: return 'Sem permissão para esta ação.';
    case 404: return 'Recurso não encontrado.';
    case 409: return data?.message || 'Conflito no estado do recurso.';
    case 422: return data?.message || 'Validação falhou.';
    case 500: return 'Erro interno. Tente novamente.';
    default:  return data?.message || 'Erro desconhecido.';
  }
};
```

---

## 🔐 **SPRINT 2 (Sem 3-4): RH — ASSIDUIDADE REAL + AUSÊNCIAS**

O fluxo de assiduidade já está maduro em UI. Falta ligar ao backend real e respeitar o contrato do spec (`RH` — Assiduidade, Ausências e licenças).

### Dia 1-2: Biometria facial com detecção real

```javascript
// screens/funcionario/FaceScreen.js
import { Camera, CameraType } from 'expo-camera';
import * as FaceDetector from 'expo-face-detector';

// Liveness baseado em olhos abertos + ângulo facial + blink
// Envio para POST /api/hr/attendance/events (spec — RH > Assiduidade)
```

### Dia 3: API de eventos de assiduidade

Spec: `POST /api/hr/attendance/events`. Payload conforme eventos (entrada, saída, pausa, retoma) e métodos (biométrico, app móvel, manual).

```javascript
// src/api/attendance.js
import apiClient from './client';

export const submitAttendanceEvent = async ({ method, eventType, photo, location, deviceId }) => {
  const form = new FormData();
  form.append('method', method);         // 'face' | 'nfc' | 'qr' | 'selfie_gps' | 'pin'
  form.append('event_type', eventType);  // 'entrada' | 'saida' | 'pausa' | 'retoma'
  if (photo)    form.append('photo', { uri: photo.uri, type: 'image/jpeg', name: 'e.jpg' });
  if (location) form.append('location', JSON.stringify(location));
  if (deviceId) form.append('device_id', deviceId);

  return apiClient.post('/hr/attendance/events', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    timeout: 30000,
  });
};

export const getAttendanceHistory = (params) => apiClient.get('/hr/attendance', { params });
```

### Dia 4: GPS + geofencing

Usado por `SelfieGPSScreen` e visitas CRM.

```javascript
// src/utils/location.js
import * as Location from 'expo-location';

export const getCurrentLocation = async () => {
  const { status } = await Location.requestForegroundPermissionsAsync();
  if (status !== 'granted') throw new Error('Location permission denied');
  const loc = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.High, timeout: 15000 });
  return { latitude: loc.coords.latitude, longitude: loc.coords.longitude, accuracy: loc.coords.accuracy };
};

export const checkGeofence = async (allowed, current) => {
  // distância de Haversine vs cada ponto permitido; retorna { allowed, distance, closest }
};
```

### Dia 5: Ausências e férias (spec — RH > Ausências)

Spec: `leave.view`, `leave.approve`; um pedido aprovado atualiza saldo e registo de assiduidade.

```javascript
// src/api/leaves.js
export const submitLeaveRequest = (payload) => apiClient.post('/hr/leaves', payload);
export const listLeaveRequests  = (params)  => apiClient.get('/hr/leaves', { params });
export const approveLeave       = (id, ok)  => apiClient.post(`/hr/leaves/${id}/${ok ? 'approve' : 'reject'}`);
export const getLeaveBalance    = ()        => apiClient.get('/hr/leaves/balance');
```

Os ecrãs `SolicitarFeriasScreen`, `SolicitarFeriasFormScreen`, `DetalhePedidoScreen` passam a consumir estas rotas. No gestor, `PedidoFeriasScreen` chama `approveLeave` **apenas se `leave.approve` estiver em `permissions`**.

---

## 🏪 **SPRINT 3 (Sem 5-6): FLUXO COMERCIAL — CLIENTES → COTAÇÕES → ENCOMENDAS → ENTREGAS**

Cobre os módulos `customers`, `quotes`, `orders`, `deliveries` e respeitivas permissões.

### Clientes (`customers`)

Permissões: `client.view`, `client.create`, `client.edit`, `client.delete`.

- Lista com filtros (nome, NIF, estado)
- Detalhe com contactos e histórico comercial
- Formulário de criação/edição (gated por `client.create` / `client.edit`)
- Eliminação **bloqueada** se há faturas/encomendas/recibos ativos (spec — *Restrição Clientes*)

### Cotações (`quotes`)

Permissões: `quote.view`, `quote.create`, `quote.approve`, `quote.delete`.

- Listagem + filtros por estado
- Formulário de nova cotação (cliente, itens, preços, série documental)
- Aprovação/rejeição (**separada de criação** conforme spec)
- Conversão em encomenda (requer `order.create`)

### Encomendas (`orders`)

Permissões: `order.view`, `order.create`, `order.approve`, `order.cancel`.

- Lista + detalhe com itens
- Criação direta ou a partir de cotação aprovada
- Aprovação interna
- Cancelamento com alerta: **se há entrega associada, exige fluxo de devolução** (spec)

### Entregas (`deliveries`)

Permissões: `delivery.view`, `delivery.create`, `delivery.confirm`, `delivery.cancel`.

- Geração a partir de encomenda aprovada
- **Confirmação** mobile com captura de POD (foto + assinatura)
- Cancelamento antes de confirmação
- Confirmação dispara sincronização WMS (spec — *Restrição Entregas*)

### Payload-contrato típico

```javascript
// src/api/commercial.js
export const createQuote  = (p) => apiClient.post('/quotes', p);
export const approveQuote = (id) => apiClient.post(`/quotes/${id}/approve`);
export const convertQuoteToOrder = (id) => apiClient.post(`/quotes/${id}/convert`);
export const confirmDelivery = (id, { signature, photos }) => {
  const f = new FormData();
  f.append('signature', { uri: signature.uri, type: 'image/png', name: 'sig.png' });
  photos.forEach((ph, i) => f.append(`photo_${i}`, { uri: ph.uri, type: 'image/jpeg', name: `p${i}.jpg` }));
  return apiClient.post(`/deliveries/${id}/confirmar`, f, { headers: { 'Content-Type': 'multipart/form-data' } });
};
```

---

## 💰 **SPRINT 4 (Sem 7-8): FATURAÇÃO, RECEBIMENTOS E REGULARIZAÇÕES**

Cobre `invoices`, `receipts`, `credit-notes`, `returns`, `series`.

### Faturas (`invoices`)

Permissões: `invoice.view`, `invoice.create`, `invoice.void`.

- Emissão a partir de encomenda ou direta
- Visualização PDF
- Anulação (irreversível — spec); **pode exigir nota de crédito associada**
- Série documental escolhida via `series.manage`

### Recibos (`receipts`)

Permissões: `receipt.view`, `receipt.create`, `receipt.void`.

- Registo de recebimento com método de pagamento
- Anulação com cautela (reverte recebimento)
- Associação à fatura

### Notas de Crédito (`credit-notes`)

Permissões: `credit_note.view`, `credit_note.create`, `credit_note.void`.

- **Sempre** associada a uma fatura existente (spec)
- Emissão despoletada por anulação de fatura ou devolução

### Devoluções (`returns`)

Permissões: `return.view`, `return.create`, `return.approve`.

- Registo de devolução
- Aprovação pode gerar **movimentação de stock** e **nota de crédito** automática (spec)

### Séries Documentais (`series`)

Permissão: `series.manage`.

- Consulta de séries disponíveis por tipo de documento
- Ativação/desativação **não é feita** se há documentos emitidos (spec)

---

## 👥 **SPRINT 5 (Sem 9-10): CRM, PAYROLL, SIGNATURES, REPORTS, DASHBOARD, SETTINGS**

### CRM (`crm`)

Permissões: `crm.lead.create`, `crm.deal.create`, `crm.activity.create`.

- Criação de leads, deals, atividades (com geolocalização opcional)
- Pipeline interativo (já existe em `CRMScreen` — estender com ações de criação)
- Campanhas (v1.4 do spec)
- Tickets de atendimento (v1.4 do spec — pós-venda)

### Payroll (`payroll`)

Permissões: `payroll.view`, `payroll.process`, `payroll.approve`.

- Consulta de ciclos e resultados
- Processamento (`payroll.process`)
- Aprovação (`payroll.approve`)
- Recibos em PDF
- **Alerta do spec:** `payroll.process` está hoje colapsado em `payroll.approve` no backend — mobile deve preparar a UI para separação quando a constante for criada

### Signatures (`signatures`)

Permissões: `signature.create`, `signature.send`.

- Criação de documento para assinatura (captura via signature pad)
- Envio para assinatura (OTP do destinatário, integração com módulo de mensagens)
- Acompanhamento de estado e verificação pública

### Reports (`reports`)

Permissões: `report.view`, `report.export`.

- Dashboards e relatórios operacionais
- Exportação PDF/Excel (exige `report.export` — pressupõe `report.view`)

### Dashboard (`dashboard`)

- Acesso ao módulo `dashboard`
- Backend em placeholder — expandir quando BI avançado v1.4 expuser KPIs estruturados

### Settings (`settings`)

Permissão: `settings.manage` (combinada com `admin.tenant` recomendado).

- Preferências do tenant
- Alertas: `PUT /api/settings/` ainda não aplica guard no backend (spec — lacuna técnica) — UI deve validar reativamente

---

## 📱 **TRANSVERSAL — OFFLINE, SYNC, PUSH, NOTIFICAÇÕES, MENSAGENS**

Áreas transversais do spec (Notificações, Mensagens, Agenda, Uploads, Equipas) são **integradas ao longo dos sprints**, não num sprint dedicado. Correm em todos os módulos.

### Offline + Sync

```javascript
// src/utils/offlineStorage.js — fila de ações pendentes
export const offlineStorage = {
  addOfflineAction: async (action) => { /* ... */ },
  getOfflineQueue: async () => { /* ... */ },
  removeOfflineAction: async (id) => { /* ... */ },
  setLastSync: async (ts) => { /* ... */ },
};
```

```javascript
// src/utils/syncManager.js
import NetInfo from '@react-native-community/netinfo';
class SyncManager {
  constructor() {
    this.isOnline = false;
    this.syncInProgress = false;
    NetInfo.addEventListener((s) => {
      this.isOnline = s.isConnected;
      if (this.isOnline && !this.syncInProgress) this.performSync();
    });
  }
  async performSync() { /* envia fila: attendance events, leaves, delivery POD, CRM activities */ }
}
export const syncManager = new SyncManager();
```

**Prioridade do offline:** assiduidade, confirmação de entrega, atividades CRM de campo, leaves. Para CRUD financeiro (faturas/recibos/NC) — bloquear offline por integridade documental.

### Push Notifications

Integração com o módulo `notifications` do spec. Emitir notificação via API exige `notification.create`; **receber é livre** para qualquer utilizador autenticado.

```javascript
// src/utils/notifications.js
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

export const registerDevice = async () => {
  const { status } = await Notifications.requestPermissionsAsync();
  if (status !== 'granted' || !Device.isDevice) return null;
  const { data: pushToken } = await Notifications.getExpoPushTokenAsync();
  await apiClient.post('/users/register-device', {
    pushToken,
    deviceInfo: { platform: Device.osName, version: Device.osVersion, model: Device.modelName },
  });
  return pushToken;
};
```

Handler no `App.js`:

```javascript
useEffect(() => {
  const sub = Notifications.addNotificationResponseReceivedListener((resp) => {
    const data = resp.notification.request.content.data;
    if (data.type === 'leave_approved')     navigation.navigate('Historico');
    if (data.type === 'quote_approved')     navigation.navigate('ModuleQuotes');
    if (data.type === 'delivery_assigned')  navigation.navigate('ModuleDeliveries');
    if (data.type === 'attendance_reminder') navigation.navigate('HomeFunc');
  });
  return () => Notifications.removeNotificationSubscription(sub);
}, []);
```

### Chat / Mensagens

Os ecrãs `ChatScreen`, `ChatPrivadoScreen`, `ChatGrupoScreen` consomem o módulo `Mensagens` do spec (chat em tempo real + OTP). Requer WebSocket persistente.

---

## 🌐 **TRANSVERSAL — i18n E MULTI-MOEDA (v1.4)**

Spec v1.4 já implementa multi-idioma e multi-moeda no backend. No mobile:

### i18n

```bash
npm install i18next react-i18next expo-localization
```

```javascript
// src/i18n/index.js — pt/en/fr conforme catálogo do backend
```

### Multi-moeda

- Moeda vem do tenant / documento comercial
- Formatação alinhada com locale
- Taxa de câmbio fetched on demand em documentos multi-moeda

---

## 🔒 **TRANSVERSAL — PERMISSÕES GRANULARES**

Spec define escopos `own`/`dept`/`all` e condições como `purchase.approve.up_to_1000`.

```javascript
// src/access/granular.js
export const fetchGranularPermissions = (userId) =>
  apiClient.get(`/admin/usuarios/${userId}/granular-permissions`);

// UI aplica filtros ao pedir listagens
const listInvoices = (params) => apiClient.get('/invoices', { params: { ...params, scope: 'own' } });
```

---

## 🧪 **TESTING & VALIDATION**

### Test checklist alinhado com o spec
- ✅ **Auth:** Login retorna `{ token, user, tenant, role, cargo, permissions }`
- ✅ **Autorização:** rotas respeitam `admin.tenant`, módulos e permissões
- ✅ **Super-admin:** não acede a módulos operacionais (regra estrita)
- ✅ **Assiduidade:** `POST /api/hr/attendance/events` com os 5 métodos
- ✅ **Fluxo comercial:** cotação → encomenda → entrega → fatura → recibo
- ✅ **Regularizações:** NC sempre ligada a fatura; devolução gera stock + NC
- ✅ **Offline:** fila e sync para fluxos de campo (não para financeiro)
- ✅ **Notificações:** recepção livre; emissão só com `notification.create`
- ✅ **Performance:** telas <2s, footprint <100MB

### Debug helper
```javascript
const debugInfo = {
  api: apiClient.defaults.baseURL,
  role: await AsyncStorage.getItem('role'),
  permissions: JSON.parse(await AsyncStorage.getItem('permissions') || '[]'),
  lastSync: await offlineStorage.getLastSync(),
};
console.log('Debug:', debugInfo);
```

---

## 🚀 **DEPLOYMENT CHECKLIST**

### Pre-launch
- ✅ Variáveis de ambiente (`EXPO_PUBLIC_API_URL`) por ambiente
- ✅ HTTPS + certificate pinning
- ✅ App Store — screenshots, descrições
- ✅ Backend em produção com os **19 módulos** + permissões
- ✅ Catálogo de **permissões** sincronizado (fonte: spec.md)

### Launch
1. **Build:** `eas build --platform all`
2. **TestFlight / Internal Testing**
3. **Submit** nas lojas
4. **Monitoring:** Sentry + analytics
5. **Support:** helpdesk com acesso ao tenant de diagnóstico

---

## 📞 **SUPORTE PÓS-LANÇAMENTO**

### Monitoring
- **Crashes:** Sentry
- **Performance:** response times, memory
- **Usage:** flows por role (super-admin vs gestor vs funcionário)
- **Erros de permissão:** picos de 403 → ajuste de UI reativa
- **Lacunas técnicas do spec:** tracking das rotas que ainda não aplicam guards (spec — "Lacunas técnicas") para ativar enforcement mobile assim que o backend corrigir

### Hotfixes
- **Críticos:** <24h
- **Segurança:** patch imediato
- **Performance:** sprint de otimização

---

## 📚 Documentos relacionados

- [backend/docs/spec.md](../../backend/docs/spec.md) — spec funcional canónica (v1.4)
- [ANALISE_MODULOS_MOBILE.md](./ANALISE_MODULOS_MOBILE.md) — estado por módulo
- [GUIA.md](./GUIA.md) — guia rápido multi-persona

---

*Guia alinhado com `backend/docs/spec.md` v1.4 (2026-04-24) — substitui a versão focada apenas em assiduidade.*
