# Análise: Viabilidade de ERP Mobile no Nexora ERP

## Contexto

Este documento avalia a viabilidade técnica de criar uma aplicação **ERP Mobile** consumindo o backend `factPro/backend` (Nexora ERP), considerando a arquitetura actual, autenticação, módulos existentes e limitações.

---

## 1. Arquitetura actual do backend

| Aspecto | Estado actual | Implicação para mobile |
|---|---|---|
| Framework | Go 1.25 + `go-chi/chi` | RESTful, leve, adequado para mobile. |
| Formato | JSON em todas as APIs | Compatível com qualquer app mobile. |
| Estado | Stateless (sessão validada por JWT) | Facilita apps sem state de servidor. |
| DB | PostgreSQL `nexora_erp` via `pgx/v5` | Boa performance para queries mobile. |
| Auth | JWT HS256 (`JWT_SECRET`) + sessões em `auth.sessions` | Suporta login mobile nativo. |
| CORS | Configurado via `cfg.CORSOrigin` | App mobile via webview ou HTTP precisa de origem permitida. |
| Uploads | Storage abstrato (local/MinIO/S3) | Suporta envio de fotos/documentos do mobile. |
| Push | Firebase Admin SDK | Já preparado para notificações push. |

**Conclusão:** a base técnica já suporta um app mobile.

---

## 2. Autenticação e sessões

### 2.1 JWT e claims

O token de acesso contém:

```go
claims := jwt.MapClaims{
    "sub":    userID,
    "tid":    tenantID,
    "tipo":   tipo,     // superadmin | funcionario | aluno | encarregado | candidato
    "escopo": escopo,   // erp | escola | portal_professor
    "jti":    jti,
    "exp":    time.Now().Add(h.cfg.JWTExpiresIn).Unix(),
}
```

### 2.2 Escopos actuais

| Escopo | Destino |
|---|---|
| `erp` | Painel ERP principal |
| `escola` | Gestão escolar |
| `portal_professor` | Portal do professor |
| `portal_aluno` | Portal do aluno |
| `portal_encarregado` | Portal do encarregado |
| `portal_candidato` | Portal do candidato |

### 2.3 Proposta para ERP Mobile

Criar um novo escopo **`mobile_erp`** (ou **`erp_mobile`**) para distinguir o app móvel do web ERP. Isso permite:

- Aplicar políticas específicas (ex: refresh token mais longo, restrições de IP).
- Controlar permissões mobile separadamente.
- Logar sessões mobile de forma distinta.

Alternativamente, reutilizar o escopo `erp` e confiar no `User-Agent`/`source` para distinguir, mas isso é menos seguro e menos flexível.

---

## 3. Portais existentes vs. ERP Mobile

O Nexora ERP já tem portais para públicos externos (aluno, encarregado, candidato). O **ERP Mobile** seria diferente:

- Destinado a **funcionários/administradores internos** da empresa.
- Acesso a módulos operacionais: RH, faturação, stock, CRM, aprovações, tarefas.
- Deve respeitar o RBAC do ERP (`auth.cargos`, `auth.permissoes_cargo`).

### Módulos adequados para mobile

| Módulo | Adequação mobile | Notas |
|---|---|---|
| **Recursos Humanos** | Alta | consulta de presenças, pedidos de férias, recibos, self-service. |
| **Aprovações** | Alta | aprovar/rejeitar requisições, férias, despesas. |
| **Tarefas** | Alta | gestão de tarefas, atribuições, prazos. |
| **CRM** | Média/Alta | visualizar leads, oportunidades, adicionar actividades. |
| **Faturação** | Média | consultar facturas, clientes; criação simples. |
| **Stock** | Média | consulta de inventário, movimentações simples. |
| **Contabilidade** | Baixa | complexa, relatórios detalhados, melhor no web. |
| **Compras** | Média | aprovações, requisições. |
| **Gestão Escolar** | Alta (portal) | já existe portal mobile-ready para alunos/encarregados. |

---

## 4. Endpoints e rotas relevantes para mobile

Do `internal/router/router.go`, rotas que podem ser reaproveitadas para mobile:

### Auth
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/auth/me`
- `GET /api/auth/me/acesso`

### RH / Self-service
- `GET /api/rh/funcionarios/{id}`
- `GET /api/rh/funcionarios/{id}/presencas`
- `POST /api/rh/funcionarios/{id}/pedido-ferias`
- Self-service: consulta de recibos, dados pessoais.

### Aprovações
- `GET /api/aprovacoes/requests`
- `POST /api/aprovacoes/requests/{id}/approve`
- `POST /api/aprovacoes/requests/{id}/reject`

### Tarefas
- `GET /api/tarefas`
- `POST /api/tarefas`
- `PUT /api/tarefas/{id}/status`

### CRM
- `GET /api/crm/leads`
- `GET /api/crm/oportunidades`
- `POST /api/crm/atividades`

### Notificações
- `GET /api/notifications`
- `POST /api/notifications/{id}/read`
- Push via Firebase.

---

## 5. Mudanças necessárias no backend

### 5.1 Novo escopo mobile

Adicionar `mobile_erp` ao middleware de escopo:

```go
// internal/middleware/auth.go
func escopoPermitidoParaPath(path, escopo string) bool {
    switch {
    case strings.HasPrefix(path, "/api/mobile"):
        return escopo == "mobile_erp"
    case strings.HasPrefix(path, "/api/escolar"):
        return escopo == "escola"
    // ... resto
    }
}
```

E no login, permitir que um utilizador peça escopo mobile:

```json
{
  "email": "user@empresa.com",
  "password": "...",
  "escopo": "mobile_erp"
}
```

### 5.2 Novo prefixo de rotas mobile (opcional)

Criar `/api/mobile/*` para endpoints otimizados para mobile:

- Resumos/dashcards (`/api/mobile/dashboard`).
- Listas simplificadas (`/api/mobile/tarefas`, `/api/mobile/aprovacoes`).
- Upload de fotos compactadas.

Isso não impede reaproveitar `/api/rh/*`, `/api/crm/*`, etc., mas permite otimizar payloads para mobile.

### 5.3 Refresh token longo para mobile

No `config/config.go`:

```go
JWTRefreshExpiresIn: parseDuration(env("JWT_REFRESH_EXPIRES_IN", "7d"))
```

Para mobile, recomenda-se um refresh token mais longo (30-90 dias) ou device-bound tokens, para evitar login frequente.

### 5.4 Device registration

Adicionar registo de dispositivos móveis para push notifications:

```sql
CREATE TABLE auth.mobile_devices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL,
    device_uuid VARCHAR(255) NOT NULL,
    platform VARCHAR(20) CHECK (platform IN ('ios', 'android')),
    fcm_token TEXT,
    device_name VARCHAR(100),
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, device_uuid)
);
```

Endpoint:
- `POST /api/mobile/devices/register`
- `POST /api/mobile/devices/unregister`

### 5.5 CORS para app mobile

Se o app for híbrido (Capacitor/Flutter Web) ou usar webview, adicionar origem do app:

```go
AllowedOrigins: []string{cfg.CORSOrigin, "https://mobile.nexora.e258tech.tech", "capacitor://localhost"},
```

Para app nativo, CORS não se aplica; basta enviar `Authorization: Bearer <token>`.

### 5.6 Otimização de payloads

Alguns endpoints ERP retornam dados pesados (ex: listagens de facturas com muitos campos). Para mobile, criar versões resumidas:

```go
// Exemplo: GET /api/mobile/faturacao/facturas?resumo=true
{
  "id": 123,
  "numero": "FT 2026/001",
  "cliente": "Cliente X",
  "total": 15000.00,
  "estado": "paga",
  "data": "2026-07-10"
}
```

---

## 6. Funcionalidades recomendadas para MVP mobile

### Fase 1 — Login e dashboard
- Login com email/password.
- Dashboard com resumo: tarefas pendentes, aprovações pendentes, próximas férias.
- Perfil do utilizador.

### Fase 2 — Aprovações e tarefas
- Listar pedidos de aprovação.
- Aprovar/rejeitar com comentário.
- Listar tarefas.
- Actualizar estado de tarefas.

### Fase 3 — RH / Self-service
- Consultar presenças.
- Pedir férias.
- Consultar recibos.
- Justificar faltas/atrasos.

### Fase 4 — CRM e operações
- Visualizar leads/oportunidades.
- Registar actividades.
- Consultar stock rápido.

### Fase 5 — Notificações push
- Push para novas aprovações.
- Push para tarefas atribuídas.
- Push para alertas de RH.

---

## 7. Limitações e riscos

| Risco | Descrição | Mitigação |
|---|---|---|
| Escopos restritivos | Hoje `RestricaoEscopo` força `/api/*` → `erp`. App mobile precisa de `erp` ou novo escopo. | Adicionar `mobile_erp` e rotas `/api/mobile/*`. |
| Payloads pesados | Alguns endpoints retornam muitos campos. | Criar endpoints `/api/mobile/*` resumidos. |
| Refresh token curto | 7 dias pode ser curto para app mobile. | Configurar refresh token longo para escopo mobile. |
| Uploads grandes | Fotos do mobile podem ser grandes. | Comprimir no app antes de enviar; usar storage já existente. |
| Permissões granulares | Mobile deve respeitar RBAC do ERP. | Reutilizar `RequirePermission` nas rotas mobile. |
| Sessões simultâneas | App mobile + web ERP podem criar muitas sessões. | Limitar sessões por device ou tipo. |

---

## 8. Conclusão

> **Sim, é viável criar um ERP Mobile sobre o Nexora ERP.** O backend já tem os alicerces necessários: REST API, JWT auth, multi-tenancy, RBAC, push notifications e storage.

A abordagem recomendada é:

1. **Criar escopo `mobile_erp`** e permitir login com esse escopo.
2. **Criar rotas `/api/mobile/*`** para endpoints otimizados (dashboard, aprovações, tarefas, RH).
3. **Reaproveitar** `/api/rh/*`, `/api/crm/*`, `/api/tarefas/*`, `/api/aprovacoes/*` sempre que possível.
4. **Adicionar registo de dispositivos móveis** para push notifications.
5. **MVP focado**: login, dashboard, aprovações, tarefas e RH self-service.

---

## 9. Próximos passos sugeridos

1. Validar com produto quais módulos fazem parte do MVP mobile.
2. Decidir se o app será nativo, Flutter, React Native ou PWA.
3. Adicionar escopo `mobile_erp` ao backend.
4. Criar endpoint `/api/mobile/dashboard` como prova de conceito.
5. Implementar login mobile e refresh token longo.
6. Criar tabela `auth.mobile_devices` e endpoints de registo.
