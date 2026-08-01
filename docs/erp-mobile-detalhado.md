# ERP Mobile — Documento Detalhado de Implementação

## 1. Visão geral

Este documento detalha a implementação de um **ERP Mobile** sobre o backend Nexora ERP (`factPro/backend`). O objectivo é disponibilizar uma aplicação móvel para funcionários e gestores acederem a funcionalidades operacionais do ERP (RH, aprovações, tarefas, CRM, etc.), reaproveitando ao máximo a infraestrutura e APIs existentes.

### 1.1 Porquê ERP Mobile?

- **Aprovações em movimento:** gestores precisam de aprovar férias, despesas, requisições fora do escritório.
- **Self-service RH:** consulta de presenças, recibos, pedidos de férias.
- **Tarefas e CRM:** acompanhamento de actividades e oportunidades em tempo real.
- **Notificações push:** alertas imediatos para acções pendentes.

### 1.2 Princípios orientadores

1. **Reaproveitar o backend existente** — não recriar auth, RBAC, tenants, etc.
2. **Mínima intrusão** — adicionar escopo/rotas mobile sem quebrar o ERP web.
3. **Segurança primeiro** — tokens device-bound, refresh controlado, network isolation.
4. **Performance mobile** — payloads reduzidos, endpoints específicos para app.

---

## 2. Arquitetura proposta

### 2.1 Diagrama de alto nível

```
┌─────────────────────────────────────────────────────────────────────┐
│                         APP MOBILE                                  │
│  (Flutter / React Native / Nativo)                                  │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │ Login       │  │ Dashboard   │  │ Aprovações  │  │ Tarefas   │  │
│  │ Notificações│  │ RH          │  │ CRM         │  │ ...       │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘  │
└────────────────────┬────────────────────────────────────────────────┘
                     │ HTTPS / JSON
                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Traefik / API Gateway                          │
│  (termina TLS, rate limiting, encaminha para backend)               │
└────────────────────┬────────────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌─────────────────┐      ┌─────────────────────┐
│   Nexora ERP    │      │   FaceClock         │
│  (factPro/backend)      │  (assiduidade)      │
│                 │      │                     │
│  /api/auth/*    │      │  /api/v1/biometric  │
│  /api/mobile/*  │      │  /api/v1/clock      │
│  /api/rh/*      │      │                     │
│  /api/crm/*     │      │                     │
│  ...            │      │                     │
└─────────────────┘      └─────────────────────┘
```

### 2.2 Escolha de tecnologia do app

| Opção | Prós | Contras |
|---|---|---|
| **Flutter** | UI consistente, bom desempenho, uma codebase para iOS/Android. | Curva de aprendizado, plugins nativos. |
| **React Native** | Grande comunidade, reaproveita React. | Performance inferior a nativo/Flutter. |
| **Nativo (Kotlin/Swift)** | Melhor performance e integração. | Duas codebases, mais caro. |
| **PWA / Capacitor** | Rápido, partilha código com web. | Limitações nativas, push menos fiável. |

**Recomendação:** **Flutter** ou **React Native**, dependendo da experiência da equipa. Para integração biométrica/câmara nativa, ambos têm bom suporte.

### 2.3 Versionamento da API

O backend actual não tem versionamento explícito na URL (`/api/auth`, `/api/rh`, etc.). Para o ERP Mobile, recomenda-se introduzir versionamento progressivo:

- Manter endpoints existentes como estão para compatibilidade web.
- Criar novos endpoints mobile com prefixo `/api/v1/mobile/*` ou `/api/mobile/v1/*`.

Exemplo:

```
/api/auth/login              (existente)
/api/v1/mobile/dashboard     (novo, versionado)
/api/v1/mobile/tarefas       (novo, versionado)
```

Isso facilita evolução futura sem quebrar o app publicado nas lojas.

### 2.4 Gaps identificados no backend

| Gap | Impacto | Solução |
|---|---|---|
| Falta de endpoint genérico de registo de push token | Notificações push só funcionam para candidatos hoje. | Generalizar `/api/notifications/push-token` ou criar `/api/mobile/devices/register`. |
| Ausência de camada `/api/mobile/*` otimizada | Payloads web podem ser pesados para mobile. | Criar endpoints mobile agregados e resumidos. |
| Ausência de versionamento de API | Dificulta evolução sem quebrar clientes. | Introduzir `/api/v1/...` para novos endpoints. |
| Escopos actuais não distinguem mobile | Não é possível aplicar políticas específicas de mobile. | Adicionar escopo `mobile_erp`. |

---

## 3. Autenticação e sessões mobile

### 3.1 Novo escopo `mobile_erp`

O token JWT actual usa `escopo`. Criar um novo escopo permite políticas específicas para mobile.

```go
// internal/middleware/auth.go
func escopoPermitidoParaPath(path, escopo string) bool {
    switch {
    case strings.HasPrefix(path, "/api/mobile"):
        return escopo == "mobile_erp"
    case strings.HasPrefix(path, "/api/escolar"):
        return escopo == "escola"
    case strings.HasPrefix(path, "/api/auth"), strings.HasPrefix(path, "/api/portal"):
        return true
    case strings.HasPrefix(path, "/api/"):
        return escopo == "erp" || escopo == "mobile_erp"
    default:
        return true
    }
}
```

### 3.2 Login mobile

O body do login pode aceitar um campo opcional `escopo`:

```json
POST /api/auth/login
{
  "email": "gestor@empresa.com",
  "password": "...",
  "escopo": "mobile_erp"
}
```

O handler `auth.Login` já consulta `auth.memberships` para obter o escopo. Adaptar para:
- Se o utilizador pedir `mobile_erp`, validar se tem permissão (por cargo/permissão).
- Se não pedir, manter comportamento actual.

### 3.3 Refresh token device-bound

Para mobile, recomenda-se refresh tokens mais longos (30-90 dias) ligados ao device.

```go
// config/config.go
JWTRefreshExpiresInMobile: parseDuration(env("JWT_REFRESH_EXPIRES_IN_MOBILE", "30d"))
```

No login mobile, guardar o device UUID na sessão:

```sql
ALTER TABLE auth.sessions ADD COLUMN device_uuid VARCHAR(255);
ALTER TABLE auth.sessions ADD COLUMN platform VARCHAR(20);
```

### 3.4 Registo de dispositivos

O backend já tem infraestrutura de push notifications via Firebase (`internal/push`). Existe um endpoint específico para candidatos:

```
POST /api/notifications/push-token
{
  "token": "fcm_token",
  "platform": "android|ios"
}
```

Para o ERP Mobile, é necessário **generalizar** este mecanismo para todos os perfis (funcionários, gestores) e associar o token a um dispositivo específico.

Criar tabela para gestão de dispositivos e push tokens:

```sql
CREATE TABLE auth.mobile_devices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL,
    device_uuid VARCHAR(255) NOT NULL,
    platform VARCHAR(20) CHECK (platform IN ('ios', 'android')),
    fcm_token TEXT,
    device_name VARCHAR(100),
    app_version VARCHAR(20),
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, device_uuid)
);

CREATE INDEX idx_mobile_devices_user ON auth.mobile_devices(user_id);
CREATE INDEX idx_mobile_devices_tenant ON auth.mobile_devices(tenant_id);
```

Endpoints:

```go
POST /api/mobile/devices/register
{
  "device_uuid": "uuid-do-dispositivo",
  "platform": "android",
  "fcm_token": "...",
  "device_name": "Samsung Galaxy S24",
  "app_version": "1.0.0"
}

POST /api/mobile/devices/unregister
{
  "device_uuid": "uuid-do-dispositivo"
}
```

Reaproveitar `internal/push.RegisterToken(ctx, user.ID, token, platform)` para guardar o FCM token.

### 3.5 Revogação de sessões

No `change-password` e logout, revogar sessões do device:

```sql
UPDATE auth.sessions
   SET ativa = FALSE, encerrado_em = NOW()
 WHERE user_id = $1 AND device_uuid = $2;
```

---

## 4. Modelo de dados mobile

### 4.1 Entidades novas

| Entidade | Schema | Finalidade |
|---|---|---|
| `mobile_devices` | `auth` | Registo de dispositivos e tokens FCM. |
| `mobile_sessions` | `auth` | Poderia ser apenas colunas adicionadas em `auth.sessions`. |
| `mobile_feature_flags` | `sistema_configuracao` | Funcionalidades mobile activas por tenant. |

### 4.2 Alterações em tabelas existentes

```sql
-- Adicionar escopo mobile na membership
ALTER TABLE auth.memberships ADD COLUMN permite_mobile BOOLEAN DEFAULT FALSE;

-- Adicionar device à sessão
ALTER TABLE auth.sessions ADD COLUMN device_uuid VARCHAR(255);
ALTER TABLE auth.sessions ADD COLUMN platform VARCHAR(20);
```

---

## 5. API Mobile detalhada

### 5.1 Prefixo `/api/mobile`

Criar um novo router em `internal/router/router.go`:

```go
r.Route("/api/mobile", func(r chi.Router) {
    r.Use(mw.RequireAuth(cfg.JWTSecret, db))
    r.Use(mw.RequireEscopo("mobile_erp", "erp")) // ou só mobile_erp

    r.Get("/dashboard", mobile.Dashboard)
    r.Get("/tarefas", mobile.ListarTarefas)
    r.Put("/tarefas/{id}/status", mobile.ActualizarTarefa)
    r.Get("/aprovacoes", mobile.ListarAprovacoesPendentes)
    r.Post("/aprovacoes/{id}/approve", mobile.Aprovar)
    r.Post("/aprovacoes/{id}/reject", mobile.Rejeitar)
    r.Get("/rh/presencas", mobile.ListarPresencas)
    r.Post("/rh/pedido-ferias", mobile.PedirFerias)
    r.Get("/crm/dashboard", mobile.CRMDashboard)
    r.Get("/notificacoes", mobile.ListarNotificacoes)
    r.Post("/devices/register", mobile.RegisterDevice)
    r.Post("/devices/unregister", mobile.UnregisterDevice)
})
```

### 5.2 Endpoint `/api/mobile/dashboard`

Resposta otimizada para mobile:

```json
{
  "user": {
    "id": 123,
    "nome": "João Silva",
    "cargo": "Gestor de RH",
    "tenant_id": 1,
    "foto_url": "https://.../avatars/123.jpg"
  },
  "resumo": {
    "tarefas_pendentes": 5,
    "aprovacoes_pendentes": 3,
    "notificacoes_nao_lidas": 7,
    "proximas_ferias": "2026-08-15"
  },
  "atalhos": ["tarefas", "aprovacoes", "rh", "crm"]
}
```

### 5.3 Endpoint `/api/mobile/tarefas`

```json
GET /api/mobile/tarefas?status=pending&page=1&page_size=20

{
  "items": [
    {
      "id": 1,
      "titulo": "Revisar proposta comercial",
      "status": "pendente",
      "prioridade": "alta",
      "prazo": "2026-07-15",
      "responsavel": "João Silva"
    }
  ],
  "page": 1,
  "page_size": 20,
  "total": 45
}
```

### 5.4 Endpoint `/api/mobile/aprovacoes`

```json
GET /api/mobile/aprovacoes?status=pending

{
  "items": [
    {
      "id": 101,
      "tipo": "ferias",
      "solicitante": "Maria Costa",
      "descricao": "Pedido de férias: 10 a 20 de Agosto",
      "data_solicitacao": "2026-07-10",
      "status": "pendente"
    }
  ]
}
```

```json
POST /api/mobile/aprovacoes/101/approve
{
  "comentario": "Aprovado. Bom descanso!"
}

POST /api/mobile/aprovacoes/101/reject
{
  "comentario": "Não é possível nesta data."
}
```

### 5.5 Endpoint `/api/mobile/rh/presencas`

```json
GET /api/mobile/rh/presencas?mes=7&ano=2026

{
  "mes": 7,
  "ano": 2026,
  "dias_trabalhados": 18,
  "faltas": 1,
  "atrasos": 2,
  "horas_extra": 4.5,
  "dias": [
    {
      "data": "2026-07-10",
      "hora_entrada": "08:05",
      "hora_saida": "17:10",
      "horas_extra": 0.5,
      "status": "normal"
    }
  ]
}
```

### 5.6 Endpoint `/api/mobile/notificacoes`

```json
GET /api/mobile/notificacoes?nao_lidas=true

{
  "items": [
    {
      "id": 55,
      "titulo": "Nova tarefa atribuída",
      "mensagem": "Foi-lhe atribuída a tarefa 'Revisar contrato'.",
      "lida": false,
      "created_at": "2026-07-10T09:30:00Z"
    }
  ]
}
```

---

## 6. Segurança

### 6.1 Transporte

- TLS 1.2+ obrigatório.
- Certificate pinning opcional no app.
- Não enviar tokens por URL.

### 6.2 Armazenamento no dispositivo

- Guardar tokens no Keychain (iOS) ou Keystore (Android), nunca em SharedPreferences/NSUserDefaults.
- Usar bibliotecas como `flutter_secure_storage` ou `react-native-keychain`.

### 6.3 Sessões

- Limitar número de dispositivos por utilizador (ex: máximo 3).
- Invalidar sessões de dispositivos inactivos após 90 dias.
- Permitir revogação remota de dispositivos.

### 6.4 Permissões

Reutilizar o RBAC existente:

```go
r.With(
    mw.RequireAuth(cfg.JWTSecret, db),
    mw.RequireEscopo("mobile_erp"),
    mw.RequirePermission(db, "recursos-humanos", "consultar_presencas"),
).Get("/api/mobile/rh/presencas", mobile.ListarPresencas)
```

---

## 7. Notificações push

### 7.1 Integração Firebase

O backend já usa Firebase Admin SDK (`internal/push`). Já existe um endpoint de registo de token push para o portal de candidatos:

```
POST /api/notifications/push-token
{
  "token": "fcm_token",
  "platform": "android|ios"
}
```

Para o ERP Mobile, este mecanismo deve ser **generalizado** para todos os utilizadores, associando o token ao `device_uuid` e ao `tenant_id`.

### 7.2 Eventos que geram push

| Evento | Destinatário |
|---|---|
| Nova tarefa atribuída | Utilizador atribuído. |
| Nova aprovação pendente | Aprovador. |
| Pedido de férias aprovado/rejeitado | Solicitante. |
| Alerta de RH (atrasos, faltas) | Gestor RH + funcionário. |
| Mensagem de chat | Participantes. |

### 7.3 Payload de notificação

```json
{
  "notification": {
    "title": "Nova aprovação pendente",
    "body": "Maria Costa pediu férias de 10 a 20 de Agosto."
  },
  "data": {
    "tipo": "aprovacao",
    "entity_id": "101",
    "screen": "/aprovacoes/101"
  }
}
```

---

## 8. Implementação por fases

### Fase 1 — Foundation (2-3 semanas)

- Criar escopo `mobile_erp`.
- Criar tabela `auth.mobile_devices`.
- Criar endpoints `/api/mobile/devices/register` e `/api/mobile/devices/unregister`.
- Adaptar login para aceitar `escopo` no body.
- Configurar refresh token longo para mobile.

### Fase 2 — Dashboard e navegação (2 semanas)

- Criar `/api/mobile/dashboard`.
- Criar estrutura base do app mobile.
- Implementar login/logout no app.
- Implementar navegação por módulos.

### Fase 3 — Tarefas e aprovações (3 semanas)

- Criar endpoints mobile para tarefas.
- Criar endpoints mobile para aprovações.
- Implementar listas e acções no app.
- Adicionar notificações push para novas tarefas/aprovações.

### Fase 4 — RH self-service (3 semanas)

- Criar endpoints mobile para presenças.
- Criar endpoint para pedido de férias.
- Consulta de recibos (PDF/imagens).
- Integração com FaceClock para registo de ponto via mobile.

### Fase 5 — CRM e operações (3 semanas)

- Dashboard CRM.
- Listagem de leads/oportunidades.
- Registo rápido de actividades.

### Fase 6 — Produção (2 semanas)

- Testes end-to-end.
- Hardening de segurança.
- Monitoramento.
- Publicação nas lojas.

---

## 9. Checklist de decisões

- [ ] Qual tecnologia do app? (Flutter / React Native / Nativo)
- [ ] MVP inclui quais módulos?
- [ ] Login mobile aceita só email/password ou também PIN/biometria local?
- [ ] Limite de dispositivos por utilizador?
- [ ] Refresh token mobile: 30 dias? 90 dias?
- [ ] Integração biométrica no app nativo ou via FaceClock?
- [ ] Offline support? (ex: tarefas disponíveis offline)
- [ ] Deep linking para notificações?

---

## 10. Conclusão

> **A criação de um ERP Mobile sobre o Nexora ERP é viável e alinhada com a arquitetura actual.** O backend é RESTful, JSON, stateless, com JWT refresh/logout, RBAC, multi-tenancy, paginação, storage S3/MinIO e Firebase Cloud Messaging.

A estratégia recomendada é:

1. **Reaproveitar** endpoints existentes: `/api/auth`, `/api/self-service`, `/api/aprovacoes`, `/api/tarefas`, `/api/crm`.
2. **Complementar** com endpoints mobile agregados e otimizados: `/api/v1/mobile/*`.
3. **Generalizar** o registo de push tokens para todos os perfis (não só candidatos).
4. **Adicionar** escopo `mobile_erp` para políticas e sessões específicas.
5. **Introduzir** versionamento de API para evolução segura.

Os principais gaps a resolver são: endpoint genérico de push token, camada `/api/mobile/*` otimizada, versionamento de API e distinção de escopo mobile.

O MVP recomendado foca em **login, dashboard, aprovações, tarefas e RH self-service**, garantindo valor imediato para gestores e colaboradores.
