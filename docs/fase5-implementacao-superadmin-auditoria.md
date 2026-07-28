# Fase 5 — Superadmin e Auditoria

> Data: 2026-07-27

## Resumo

Esta fase reforça a segurança administrativa do Nexora ERP: ativa a allowlist
de IPs para superadmin, introduz reautenticação step-up para operações
críticas, e alarga a auditoria a módulos que ainda não a possuíam.

## Alterações realizadas

### 1. Allowlist de IPs para superadmin

Novo middleware `backend/internal/middleware/superadmin_security.go`:

- `RequireSuperadminIPAllowlist(db)` verifica se o IP do superadmin está
  contido num CIDR de `auth.superadmin_ip_allowlist` onde `ativo = true`.
- Se a tabela estiver vazia, permite o acesso (modo transição) para não
  brickar o acesso durante a configuração inicial.
- Suporta CIDR e IPs simples; usa `r.RemoteAddr` (o middleware chi RealIP já
  extrai o IP real quando há proxies).

Aplicado no grupo `/api/superadmin`, após `RequireSuperadmin`.

### 2. Gestão da allowlist

Novos handlers em `backend/internal/modules/superadmin/handlers/security.go`:

- `GET /api/superadmin/ip-allowlist` — listar entradas.
- `POST /api/superadmin/ip-allowlist` — criar entrada (`ip_cidr`, `descricao`).
- `DELETE /api/superadmin/ip-allowlist/{id}` — desactivar entrada.

### 3. Reautenticação step-up

- `AuthUser` ganhou campo `ReauthAt`.
- `RequireAuth` e `RequireJWT` extraem o claim `reauth_at` do token (fallback
  para `iat`).
- `signOAuthAccessToken` passou a incluir `reauth_at` nos claims.
- Novo middleware `RequireSuperadminReauth(maxAge)` exige reautenticação
  recente para operações críticas de superadmin.
- Novo endpoint `POST /api/auth/reauth` em
  `backend/internal/modules/auth/handlers/authcode.go`: valida password e/ou
  TOTP do utilizador autenticado e emite novo access token com `reauth_at`
  atualizado.

Aplicado nas rotas críticas de superadmin com janela de 15 minutos:

- `/api/superadmin/tenants/*`
- `/api/superadmin/plans/*`
- `/api/superadmin/modules/*`
- `/api/superadmin/features/*`
- `/api/superadmin/settings/*`

### 4. Permissões granulares de superadmin

Mantido o modelo atual em que superadmin tem bypass total. A segurança é
compensada por:

1. IP allowlist obrigatória (quando configurada).
2. Reautenticação step-up para mutações críticas.
3. Auditoria completa das ações de superadmin.

### 5. Auditoria alargida

Adicionado `mw.AuditModule` aos módulos prioritários:

| Módulo | Middleware |
|---|---|
| `/api/superadmin` | `AuditModule(db, "/api/superadmin", "superadmin")` |
| `/api/auth` | `AuditModule(db, "/api/auth", "auth")` |
| `/api/authcode` | `AuditModule(db, "/api/authcode", "auth")` |
| `/api/companies` | `AuditModule(db, "/api/companies", "empresas")` |
| `/api/faturacao` | `AuditModule(db, "/api/faturacao", "faturacao")` |
| `/api/crm` | `AuditModule(db, "/api/crm", "crm")` |
| `/api/pos` | `AuditModule(db, "/api/pos", "pos")` |

Módulos que já tinham auditoria mantiveram-na inalterada.

## Validação

```bash
cd backend && go build ./...
cd backend && go test ./...
cd backend && go vet ./...
```

Todos os comandos terminaram com sucesso.

## Notas operacionais

- Para activar a restrição por IP, insira pelo menos um CIDR em
  `auth.superadmin_ip_allowlist` via `POST /api/superadmin/ip-allowlist`.
- Antes de configurar a allowlist, garanta que o IP de administração actual
  está incluído para evitar bloqueio do próprio acesso.
- O frontend deve chamar `POST /api/auth/reauth` com password e/ou TOTP antes
  de permitir que um superadmin execute operações críticas; o novo access
  token devolvido deve ser usado nos pedidos subsequentes.
