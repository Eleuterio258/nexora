# Análise do Fluxo de Login por Módulo

> Data: 2026-07-29  
> Tecnologias analisadas: Go (backend ERP), PHP (frontend web), Kotlin/Android, Python/FastAPI (FaceClock), Flutter (Recrutamento, School, Pay), Java/Swing (Desktop OmnisysERP)

---

## Índice

1. [Visão geral](#visão-geral)
2. [Conceitos: `tipo` vs `escopo`](#conceitos-tipo-vs-escopo)
3. [Backend Nexora ERP](#backend-nexora-erp)
4. [Frontend Web PHP](#frontend-web-php)
5. [Android Assiduidade](#android-assiduidade)
6. [Backend FaceClock](#backend-faceclock)
7. [Flutter Recrutamento](#flutter-recrutamento)
8. [Flutter School](#flutter-school)
9. [Flutter Pay](#flutter-pay)
10. [Desktop OmnisysERP](#desktop-omnisyserp)
11. [Análise de boas práticas](#análise-de-boas-práticas)
12. [Recomendações prioritárias](#recomendações-prioritárias)

---

## Visão geral

O backend **Nexora ERP** (Go) é a fonte única de identidade para quase todos os módulos. Cada cliente (web, mobile, desktop) autentica-se contra ele, recebe tokens JWT e depois consome APIs protegidas com `Authorization: Bearer <token>`.

```
┌─────────────────┐      POST /api/auth/login       ┌─────────────────┐
│  Frontend PHP   │ ───────────────────────────────▶│  Backend Go     │
│  Android App    │      ou /oauth/token            │  (Nexora ERP)   │
│  Flutter Apps   │                                 │                 │
│  Desktop Java   │◀──────── access_token +       │                 │
│  FaceClock      │            refresh_token        │                 │
└─────────────────┘                                 └─────────────────┘
```

O **FaceClock** não emite tokens próprios: valida os tokens do ERP localmente via JWKS.

---

## Conceitos: `tipo` vs `escopo`

### `tipo` — quem é a conta

Define a natureza da conta no sistema. Vem da tabela `auth.users`.

| Tipo | Significado |
|------|-------------|
| `superadmin` | Administrador global do sistema |
| `funcionario` | Trabalhador da empresa/escola |
| `aluno` | Estudante |
| `encarregado` | Pai/mãe/tutor de aluno |
| `candidato` | Pessoa a concorrer a vagas |

Uma mesma pessoa física pode ter vários `tipos` (ex: funcionária + candidata + encarregada). No login, o backend devolve a lista completa em `tipos`.

### `escopo` — onde pode entrar

Define o painel/interface acessível na sessão atual. Vem da `auth.memberships` (funcionários) ou é fixo por tipo (portais).

| Escopo | Destino |
|--------|---------|
| `erp` | Painel administrativo/comercial/RR.HH. (`/nexora/`) |
| `escola` | Painel de gestão escolar (`/escola/`) |
| `portal_professor` | Portal do professor (`/portal/professor/`) |
| `portal_aluno` | Portal do aluno (`/portal/aluno/`) |
| `portal_encarregado` | Portal do encarregado (`/portal/encarregado/`) |
| `portal_candidato` | Área do candidato (`/carreira/candidato/`) |
| `superadmin` | Painel de superadministração (`/nexora/superadmin/`) |

### Exemplo prático

Uma pessoa pode ser:
- `funcionaria` da Nexora → escopo `erp`
- `professora` numa escola → escopo `portal_professor`
- `encarregada` de um aluno → escopo `portal_encarregado`

Ao fazer login, o token leva um escopo só. O frontend PHP permite trocar de papel em `/nexora/papel/{tipo}`, que chama `POST /api/auth/papel` no backend.

---

## Backend Nexora ERP

### Tecnologia

Go + Chi router + PostgreSQL + JWT (HS256 legado, RS256 OAuth2) + bcrypt.

### Ficheiros principais

- `internal/modules/auth/handlers/auth.go` — login, refresh, me, change password
- `internal/modules/auth/handlers/oauth_token.go` — Authorization Server OAuth2
- `internal/middleware/auth.go` — `RequireAuth`, `RequireJWT`, `RequirePermission`, `RequireEscopo`
- `internal/router/router.go` — registo de rotas

### Endpoints

| Endpoint | Descrição |
|----------|-----------|
| `POST /api/auth/login` | Login unificado (email+password) |
| `POST /api/auth/refresh` | Renova access token (legado HS256) |
| `POST /oauth/token` | OAuth2: password, refresh_token, client_credentials, authorization_code |
| `GET /oauth/jwks` | Chaves públicas RS256 para validação local |
| `GET /api/auth/me` | Dados do utilizador autenticado |
| `GET /api/auth/me/acesso` | Permissões RBAC e features do tenant |
| `POST /api/auth/papel` | Troca de papel da mesma pessoa |
| `POST /api/auth/logout` | Revoga sessão atual |

### Fluxo de login

1. Recebe `email` + `password` em JSON.
2. Procura em `auth.users` + `auth.memberships` ativas.
3. Valida `password_hash` com `bcrypt.CompareHashAndPassword`.
4. Regista tentativa em `login_history` (sucesso/insucesso, IP, user-agent).
5. Descarta por tipo:
   - `aluno` → `loginAluno()`
   - `encarregado` → `loginEncarregado()`
   - `candidato` → `LoginCandidato()`
   - `funcionario`/`superadmin` → `loginFuncionario()`
6. Emite `access_token` + `refresh_token` e insere sessão em `auth.sessions`.

### Claims do token

```go
{
  "sub":    userID,
  "tid":    tenantID,
  "mid":    membershipID,
  "tipo":   "funcionario",
  "escopo": "erp",
  "jti":    "...",
  "exp":    timestamp,
  "iat":    timestamp,
  "scope":  "modulo:acao modulo2:acao2"  // só tokens OAuth2 RS256
}
```

### Pontos fortes

- bcrypt para passwords.
- JTI aleatório por token (previne replay).
- Sessões revogáveis em base de dados.
- Suporte a HS256 e RS256.
- Refresh token rotation no OAuth2.
- RBAC fino com `scope` no token.
- Step-up reauth com claim `reauth_at`.

### Pontos de atenção

- `login_history` usa goroutine fire-and-forget sem garantia de entrega.
- Uso inconsistente de `r.RemoteAddr` vs `clientIP(r)`.
- OAuth password grant (ROPC) ainda usado pelo Android; recomenda-se PKCE no médio prazo.
- Reset de password tem `TODO` de envio de email.

---

## Frontend Web PHP

### Tecnologia

PHP 8 puro/custom framework + sessões PHP nativas.

### Ficheiros principais

- `index.php` — router principal
- `src/Controller/Admin/AdminAuthController.php` — login, logout, destino, troca de papel
- `src/Infrastructure/Auth/AdminSession.php` — gestão de sessão
- `src/Infrastructure/Nexora/NexoraClient.php` — cliente HTTP para o backend Go

### Fluxo de login

1. Utilizador acede `/nexora/login`.
2. `AdminAuthController::login()` renderiza formulário com CSRF.
3. POST valida CSRF e rate-limit (`5 tentativas / 300s`).
4. Chama `POST /api/auth/login` no backend Go via `NexoraClient`.
5. `session_regenerate_id(true)`.
6. `AdminSession::store()` guarda tokens e perfil em `$_SESSION`.
7. Redireciona para `/nexora/destino` ou `?next=...` validado.

### Armazenamento de sessão

```php
$_SESSION['nexora_access_token']     // token atual
$_SESSION['nexora_refresh_token']    // refresh token
$_SESSION['nexora_token_expires_at'] // expiração
$_SESSION['nexora_escopos']          // array de escopos
$_SESSION['nexora_tipo']             // tipo da conta
$_SESSION['nexora_user']             // dados do perfil
$_SESSION['nexora_tipos']            // todos os papéis da pessoa
$_SESSION['nexora_modulos']          // permissões RBAC
```

### Página de destino

`/nexora/destino` apresenta cards para cada área disponível:

- ERP
- Escola
- Portal do Professor
- Portal do Aluno
- Portal do Encarregado
- Área do Candidato
- Superadmin

Se houver só um destino, redireciona diretamente.

### Troca de papel

`/nexora/papel/{tipo}` chama `POST /api/auth/papel` e redireciona para a área correta. Tokens de portal são guardados em chaves separadas para permitir voltar ao ERP.

### Pontos fortes

- CSRF em formulários.
- Rate limiting no login.
- Regeneração de ID de sessão.
- Validação de redirect `?next=`.
- Sincronização de permissões com TTL de 5 minutos.
- Deteção de alterações de permissões via timestamp do servidor.

### Pontos de atenção

- Token de acesso em `$_SESSION` PHP file-based pode ser um risco em shared hosting.
- Não vi mecanismo de refresh automático antes do token expirar.
- Lógica de verificação de escopo dispersa em `index.php`.
- `AdminSession::isBoth()` retorna sempre `false`.

---

## Android Assiduidade

### Tecnologia

Kotlin + Retrofit + OkHttp + EncryptedSharedPreferences + Coroutines.

### Ficheiros principais

- `ui/auth/LoginActivity.kt`
- `data/network/RetrofitClient.kt`
- `data/network/AuthAuthenticator.kt`
- `data/network/ErpApiService.kt`
- `utils/SessionManager.kt`

### Fluxo de login

1. `LoginActivity.showLoginForm()`.
2. Utilizador introduz email/password.
3. `performLogin()` chama `POST /oauth/token` (`grant_type=password`, `client_id=android-app`).
4. Recebe `OAuthTokenResponse`.
5. Timeout 5s para `GET /api/auth/me` (obrigatório) e `GET /api/auth/me/acesso`.
6. `RoleUtils.fromErpLogin(modulos)` determina papel (colaborador/gestor).
7. `SessionManager.saveSession()` persiste criptografado.
8. Mostra conteúdo principal na mesma Activity.

### Armazenamento

`EncryptedSharedPreferences` com `AES256_GCM` (MasterKey) e `AES256_SIV/GCM` (prefs). Inclui recuperação automática se o keystore estiver corrompido.

Dados guardados:

- token
- refresh token
- userId, name, email
- role
- employeeCode
- modulos RBAC
- deviceId

### Refresh automático

`AuthAuthenticator` (OkHttp) intercepta 401 e chama `POST /oauth/token?grant_type=refresh_token`. Persiste novo access token **e** novo refresh token (rotation).

### Pontos fortes

- EncryptedSharedPreferences.
- Recuperação de keystore corrompido.
- Refresh token rotation.
- OkHttp Authenticator com proteção contra loops.
- Cliente separado para refresh evitar recursão.
- Timeouts explícitos nas chamadas.
- Role por permissões RBAC, não por string fixa.

### Pontos de atenção

- OAuth password grant em cliente móvel público (ROPC).
- `employeeCode = me.email` atribuição duvidosa.
- Credenciais demo em debug (`DEMO_FUNCIONARIO_EMAIL`).
- Não chama backend no logout (apenas limpa localmente).
- API Key de device no BuildConfig é risco aceite documentado.

---

## Backend FaceClock

### Tecnologia

Python 3 + FastAPI + SQLAlchemy + PostgreSQL.

### Ficheiros principais

- `app/main.py`
- `app/deps.py`
- `app/oauth_jwks.py`
- `app/routers/biometric.py`
- `app/routers/fingerprint.py`

### Arquitetura de autenticação

O FaceClock **não faz login**. Recebe o Bearer token do ERP e valida localmente.

```python
# app/deps.py
async def get_actor(authorization: str | None = Header(...)):
    jwt_actor = await _get_actor_from_jwt(authorization)
    if jwt_actor:
        return jwt_actor
    # ou headers de gateway confiáveis
```

### Resolução de identidade

1. Tenta decifrar como JWT local (compatibilidade/testes).
2. Valida access token RS256 do ERP via JWKS (`decode_erp_access_token`).
3. Se houver headers `X-Auth-User-Id` + `X-Gateway-Secret`, aceita identidade de gateway.
4. Se nada funcionar, 401.

### Mapeamento de role

```python
if payload.get("tipo") == "superadmin":
    return "ADMIN_SISTEMA"
scope = (payload.get("scope") or "").split()
if "*" in scope or "recursos-humanos:aprovar_ausencias" in scope:
    return "GESTOR_RH"
return "COLABORADOR"
```

### Isolamento por tenant

```python
def apply_tenant(stmt, actor: ActorContext, model):
    if actor.role == "ADMIN_SISTEMA":
        return stmt
    if not actor.tenant_id:
        raise HTTPException(403, "Actor sem tenant identificado.")
    return stmt.where(model.tenant_id == actor.tenant_id)
```

### Pontos fortes

- Delega autenticação no ERP.
- Validação local via JWKS sem round-trip.
- Rejeita pedidos anónimos.
- Tenant isolation em todas as queries.
- `hmac.compare_digest` contra timing attacks.
- Logging estruturado de requests.

### Pontos de atenção ("Seguro, mas incompleto")

- Cache de JWKS pode não ter TTL/refresh automático visível.
- Não ajuda cliente a renovar token durante operações longas.
- Mapeamento de roles limitado a 3 roles; comentários indicam "Fase 1".
- Não há testes de segurança visíveis para todos os cenários.
- Sem alertas de múltiplos 401/tentativas suspeitas.
- Sem cache de tokens revogados: só sabe do `exp` do JWT.

---

## Flutter Recrutamento

### Tecnologia

Flutter + BLoC + Dio + `flutter_secure_storage` + Clean Architecture.

### Ficheiros principais

- `lib/screens/login_screen.dart`
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `lib/features/auth/data/datasources/auth_local_datasource.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/core/rest_client/dio/dio_rest_client.dart`
- `lib/core/rest_client/dio/auth_interceptor.dart`

### Fluxo de login

1. `LoginScreen` → `AuthLoginRequested`.
2. `AuthBloc` → `Login` usecase → `AuthRepositoryImpl`.
3. `AuthRemoteDataSourceImpl.login()` → `POST /api/auth/login`.
4. Extrai `candidato` ou `user` da resposta.
5. `UserModel.fromJson(...)` + cache.
6. `AuthAuthenticated` → navega para `/home`.

### Armazenamento

`flutter_secure_storage` guarda:

- `cached_user`
- `auth_token`
- `refresh_token`

### Refresh automático

`AuthInterceptor`:

- Adiciona `Authorization` quando `auth_required` é true.
- Intercepta 401 e chama `POST /api/auth/refresh`.
- Usa `_refreshing` (shared future) para evitar múltiplos refreshes concorrentes.

### Pontos fortes

- Clean Architecture.
- BLoC para estado.
- Either (`dartz`) para tratamento de erros.
- Datasources local/remote separados.
- Refresh automático com deduplicação.

### Pontos de atenção

- `auth_required` default true pode causar erros se esquecerem `.unauth()`.
- Registo faz login automático; se falhar a meio, pode ficar inconsistente.
- Não diferencia 403 de 401 no interceptor.

---

## Flutter School

### Tecnologia

Flutter + BLoC + Dio + `flutter_secure_storage`.

### Ficheiros principais

- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/core/local/local_storage/secure_local_storage_impl.dart`
- `lib/core/rest_client/dio/auth_interceptor.dart`

### Fluxo de login

1. `LoginScreen` → `LoginSubmitted`.
2. `AuthBloc` → `LoginUseCase` → `AuthRepositoryImpl`.
3. `AuthRemoteDatasourceImpl.login()` → `POST /api/auth/login`.
4. Resolve role por escopo (`portal_professor` ou `portal_aluno`).
5. Guarda token, refresh, dados do perfil em secure storage.
6. Redireciona para `/teacher-dashboard` ou `/dashboard`.

### Armazenamento

`flutter_secure_storage` com `encryptedSharedPreferences: true`. Chaves:

- `auth_token`
- `refresh_token`
- `user_id`, `user_role`, `user_name`, `user_email`
- `user_code`, `user_cargo`, `user_modulos`
- `token_expires_at`

### Pontos fortes

- Secure storage confirmado.
- BLoC simples.
- Role resolvido por escopo (mais fiável que tipo).

### Pontos de atenção

- `AuthInterceptor` apenas adiciona token; **não renova em 401**.
- Credenciais hardcoded no login screen.
- Botão "Entrar com Código de Aluno" não implementado.
- Fallback `_resolveRole` assume professor se não for aluno.

---

## Flutter Pay

### Estado atual

**Ainda não implementou autenticação.**

- Não existem ficheiros de auth/login/token.
- `main.dart` inicia em `SplashScreen` e após 5 segundos navega para `PayHomePage`.
- Admin e home usam mocks/repositórios locais.

### Ficheiros principais

- `lib/main.dart`
- `lib/features/splash/splash_screen.dart`
- `lib/core/routes/app_routes.dart`

---

## Desktop OmnisysERP

### Tecnologia

Java 17 + Spring Boot 3.3.4 + Swing + FlatLaf + RestTemplate + java-keyring.

### Ficheiros principais

- `src/main/java/tech/omnisyserp/desktop/OmnisysDesktopApp.java`
- `ui/LoginDialog.java`
- `client/BackendApiClient.java`
- `auth/TokenStore.java`

### Fluxo de login

1. Arranque tenta login silencioso com refresh token do keychain.
2. Se falhar, mostra `LoginDialog`.
3. `fazerLogin()` → `BackendApiClient.login()`.
4. `POST /api/v1/auth/login` com `username` + `password`.
5. Recebe `access_token`, `refresh_token`, dados do user.
6. `TokenStore.store()`:
   - `access_token` em memória.
   - `refresh_token` + user no keychain do SO.
7. `MainFrame` monta UI por role.

### Endpoints

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`

### Refresh automático

`BackendApiClient.withTokenRetry()` intercepta 401, renova token e repete a chamada.

### Roles

- `COLABORADOR`
- `AUDITOR`
- `GESTOR_RH`
- `ADMIN_SISTEMA`

### Pontos fortes

- Access token só em memória.
- Refresh token no keychain do SO.
- Login silencioso no arranque.
- UI baseada em roles.

### Pontos de atenção

- Usa endpoint `/api/v1/auth/login` de **outro backend** (FastAPI/controle), não do ERP Go principal.
- URL configurada como `http://209.126.86.55:8085` — HTTP em vez de HTTPS.
- `RestTemplate` está deprecated; migrar para `WebClient`/`RestClient`.
- Logout não revoga sessão no backend.

---

## Análise de boas práticas

### Matriz de maturidade

| Módulo | Segurança | Arquitetura | UX | Manutenção | Estado |
|--------|-----------|-------------|----|------------|--------|
| Backend Go | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Muito maduro |
| Frontend PHP | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Bom, mas disperso |
| Android Assiduidade | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Bem feito |
| FaceClock Python | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | Seguro, mas incompleto |
| Flutter Recrutamento | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Clean Architecture |
| Flutter School | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | Precisa de refresh |
| Flutter Pay | — | — | — | — | Sem login |
| Desktop Swing | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Bom, mas usa HTTP |

### Detalhe por módulo

#### Backend Go

**Bom:** bcrypt, JTI, dois segredos JWT, sessões revogáveis, HS256+RS256, RBAC fino no token, refresh rotation, reauth step-up, login audit.

**Melhorar:** goroutine fire-and-forget nos logs, inconsistência `r.RemoteAddr`/`clientIP`, ROPC no Android, TODO de email de reset.

#### Frontend PHP

**Bom:** CSRF, rate-limit, regeneração de sessão, validação de redirect, sync de permissões com TTL, troca de papel.

**Melhorar:** cifrar token na sessão, refresh automático, centralizar guards de escopo.

#### Android Assiduidade

**Bom:** EncryptedSharedPreferences, recuperação de keystore, refresh rotation, OkHttp Authenticator, timeouts, role por RBAC.

**Melhorar:** migrar de ROPC para PKCE, corrigir `employeeCode = email`, logout com revogação.

#### FaceClock

**Bom:** delega auth no ERP, JWKS local, rejeita anónimos, tenant isolation, HMAC constant-time.

**Melhorar:** cache JWKS com TTL, mapeamento de roles completo, testes de segurança, alertas, revogação de tokens.

#### Flutter Recrutamento

**Bom:** Clean Architecture, BLoC, Either, datasources separados, refresh com deduplicação.

**Melhorar:** default `auth_required=false`, tratamento de 403.

#### Flutter School

**Bom:** secure storage, BLoC, role por escopo.

**Melhorar:** implementar refresh em 401, remover credenciais hardcoded, implementar login por código de aluno.

#### Desktop Swing

**Bom:** token em memória + keychain, login silencioso, retry com refresh.

**Melhorar:** HTTPS, unificar backend de login, migrar RestTemplate.

---

## Recomendações prioritárias

1. **Implementar refresh automático no Flutter School** — lacuna crítica.
2. **Remover credenciais hardcoded** de todos os ambientes de release.
3. **Mudar desktop Omnisys para HTTPS** e validar certificado.
4. **Unificar endpoint de login do desktop** com o backend Go principal.
5. **Adicionar revogação de sessão no logout** de todos os clientes.
6. **Migrar Android de ROPC para PKCE** no médio prazo.
7. **Centralizar guards de escopo no PHP** para reduzir duplicação.
8. **Completar FaceClock:** cache JWKS, roles, testes de segurança, alertas.
9. **Implementar autenticação no Flutter Pay** antes de qualquer deploy.
10. **Melhorar logging assíncrono no backend Go** para não perder eventos de auditoria.

---

*Documento gerado automaticamente a partir da análise do código-fonte do projeto Nexora.*
