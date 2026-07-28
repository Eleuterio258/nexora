# Controlo de Tenant e Funcionário no Tenant Certo

## O que é um tenant?

Um **tenant** é uma "empresa" ou "organização" dentro do Nexora ERP. Cada cliente do Nexora tem o seu próprio tenant. Os dados de um tenant são completamente isolados dos outros tenants.

Exemplo:

| tenant_id | Empresa |
|-----------|---------|
| 7 | E258 Tech |
| 8 | Nexora Lda |
| 9 | Escola Exemplo |

> Quando `eleuterio.notico@e258tech.tech` faz login, o sistema sabe que ele pertence ao **tenant_id = 7**.

---

## Como o tenant é determinado no login

### 1. O utilizador faz login

```bash
POST /api/auth/login
{
  "email": "eleuterio.notico@e258tech.tech",
  "password": "1234567890"
}
```

### 2. O ERP verifica a sessão/membership

O ERP procura na tabela `auth.sessions`:

```sql
SELECT s.id, s.ativa, u.estado, COALESCE(m.tenant_id, 0)
FROM auth.sessions s
JOIN auth.users u ON u.id = s.user_id
LEFT JOIN auth.memberships m ON m.id = s.membership_id AND m.user_id = u.id
WHERE s.token_hash = HashToken(?)
  AND s.user_id = ?
  AND s.membership_id = ?;
```

O `tenant_id` vem da **membership** do utilizador (tabela `auth.memberships`).

### 3. O token JWT contém o tenant

```json
{
  "sub": 129,
  "tid": 7,
  "mid": 110,
  "tipo": "funcionario",
  "scope": "..."
}
```

- `sub` = user_id
- `tid` = tenant_id
- `mid` = membership_id

---

## Como o ERP garante isolamento por tenant

### Middleware `RequireAuth`

Todas as rotas protegidas usam o middleware `RequireAuth`. Ele:

1. Lê o token JWT.
2. Valida a assinatura.
3. Verifica se a sessão existe e está ativa.
4. Carrega o `tenant_id` do utilizador.
5. Coloca o utilizador no contexto do request.

```go
type AuthUser struct {
    ID           int64
    TenantID     int64
    MembershipID int64
    Tipo         string
    Escopo       string
    SessionID    string
}
```

### Handlers filtram por tenant

Cada handler usa `user.TenantID` para garantir que só acede aos dados do seu tenant.

Exemplo (`backend/internal/modules/recursos-humanos/handlers/funcionarios.go`):

```go
user := mw.GetUser(r)
// Query só retorna funcionários do tenant do utilizador
SELECT * FROM rh.funcionarios WHERE tenant_id = $1 AND id = $2
user.TenantID, funcionarioID
```

### O que impede ver funcionários de outro tenant?

Mesmo que alguém tente:

```bash
GET /api/rh/funcionarios/999
Authorization: Bearer <token_do_eleuterio>
```

O ERP faz:

```sql
SELECT * FROM rh.funcionarios
WHERE tenant_id = 7   -- vem do token
  AND id = 999;
```

Se o funcionário 999 pertencer ao tenant 8, a query não retorna nada → **403 ou 404**.

---

## Como o FaceClock garante isolamento por tenant

O FaceClock também isola templates biométricos por tenant.

### ActorContext no FaceClock

```python
@dataclass
class ActorContext:
    id: str | None
    role: str
    tenant_id: str | None = None
```

O `tenant_id` vem do JWT do ERP (claim `tid`) ou dos headers de confiança (`X-Auth-Tenant-Id`).

### Todas as queries aplicam tenant

```python
def apply_tenant(stmt, actor: ActorContext, model):
    if actor.tenant_id:
        return stmt.where(model.tenant_id == actor.tenant_id)
    return stmt
```

Exemplo no `biometric.py`:

```python
active_template = db.scalar(
    apply_tenant(
        select(FaceTemplate).where(
            FaceTemplate.erp_user_id == erp_user_id,
            FaceTemplate.status == TemplateStatus.ACTIVE,
        ),
        actor,
        FaceTemplate,
    )
)
```

Isso traduz-se em SQL:

```sql
SELECT * FROM face_templates
WHERE tenant_id = '7'
  AND erp_user_id = '82'
  AND status = 'ACTIVE';
```

### O que impede o ERP de aceder a templates de outro tenant?

O ERP só pode chamar o FaceClock com o `tenant_id` que vem no token JWT do utilizador. O FaceClock rejeita/restringe queries a esse tenant.

---

## Como dispositivos sabem o seu tenant

Dispositivos físicos (relógios de ponto) são registados no tenant:

```sql
SELECT id, tenant_id, nome, api_key_hash
FROM hardware.devices
WHERE id = 1;
```

| id | tenant_id | nome | api_key_hash |
|---|-----------|------|--------------|
| 1 | 7 | Relógio Entrada | sha256(...) |

Quando o dispositivo envia uma marcação:

```bash
POST /api/hardware/assiduidade/eventos
X-API-Key: nk_dev_...
{
  "funcionario_id": 82,
  "timestamp": "...",
  "metodo": "facial"
}
```

O ERP:

1. Valida a API Key.
2. Obtém `tenant_id = 7` do dispositivo.
3. Verifica se o funcionário 82 existe no tenant 7.
4. Só então grava o evento.

---

## Resumo do controlo

| Camada | Como controla o tenant |
|--------|------------------------|
| **Login** | `tenant_id` vem da `membership` do utilizador |
| **JWT** | Claim `tid` transporta o tenant |
| **Middleware ERP** | `RequireAuth` injecta `AuthUser.TenantID` |
| **Handlers ERP** | Todas as queries filtram `WHERE tenant_id = $1` |
| **FaceClock** | `ActorContext.tenant_id` + `apply_tenant()` em todas as queries |
| **Dispositivos** | `tenant_id` está registado em `hardware.devices` |

---

## Exemplo prático completo

### Cenário

Dois tenants:

- Tenant 7: E258 Tech → funcionário 82 (Eleutério)
- Tenant 8: Outra Empresa → funcionário 95 (Maria)

### Tentativa 1: Eleutério vê os seus dados

```bash
GET /api/rh/funcionarios/82
Authorization: Bearer <token_eleuterio_tid_7>
```

ERP executa:

```sql
SELECT * FROM rh.funcionarios
WHERE tenant_id = 7 AND id = 82;
```

✅ **Retorna os dados do Eleutério.**

### Tentativa 2: Eleutério tenta ver Maria

```bash
GET /api/rh/funcionarios/95
Authorization: Bearer <token_eleuterio_tid_7>
```

ERP executa:

```sql
SELECT * FROM rh.funcionarios
WHERE tenant_id = 7 AND id = 95;
```

❌ **Não retorna nada (Maria está no tenant 8).** ERP responde 404.

### Tentativa 3: Eleutério tenta usar token de outro tenant

Se alguém forjar um token com `tid = 8`, mas a sessão não existir na BD do tenant 8:

```sql
SELECT * FROM auth.sessions
WHERE token_hash = HashToken(?) AND ativa = true;
```

❌ **Sessão não encontrada.** ERP responde 401.

---

## Verificação na base de dados

### Ver tenant de um utilizador

```sql
SELECT u.id, u.email, m.tenant_id, t.nome as tenant_nome
FROM auth.users u
JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
JOIN tenants t ON t.id = m.tenant_id
WHERE u.email = LOWER('eleuterio.notico@e258tech.tech');
```

### Ver funcionários por tenant

```sql
SELECT id, nome_completo, tenant_id
FROM rh.funcionarios
WHERE tenant_id = 7
LIMIT 10;
```

### Ver dispositivos por tenant

```sql
SELECT id, nome, tenant_id
FROM hardware.devices
WHERE tenant_id = 7;
```

### Ver templates faciais por tenant no FaceClock

```sql
SELECT id, tenant_id, erp_user_id, status
FROM face_templates
WHERE tenant_id = '7';
```

---

## Conclusão

O controlo de tenant é feito em **várias camadas**:

1. **Autenticação**: o token JWT carrega o `tenant_id`.
2. **Middleware**: valida o token e injecta o tenant no contexto.
3. **Handlers**: todas as queries filtram por `tenant_id`.
4. **FaceClock**: isola templates biométricos por tenant.
5. **Dispositivos**: cada dispositivo está ligado a um tenant.

Isto garante que **nunca** um utilizador ou dispositivo acede a dados de outro tenant.

---

## Referências

- [Como Funciona a API Key](./como-funciona-api-key.md)
- [Permissões de Assiduidade: ERP vs FaceClock](./permissoes-assiduidade-erp-faceclock.md)
- `backend/internal/middleware/auth.go`
- `backend/internal/middleware/device_auth.go`
- `assiduidade_system_backend/app/deps.py`
- `assiduidade_system_backend/app/models.py`
