# Proposta — Separar `tipo` e `escopo` do Utilizador

## Contexto actual

Na tabela `auth.users` existem dois campos misturados:

| Campo | Significado actual | Valores |
|---|---|---|
| `tipo` | Tipo de actor na plataforma | `superadmin`, `funcionario` |
| `escopo` | Âmbito de acesso do funcionário | `erp`, `escola`, `ambos` |

### Motivação: adicionar `aluno` como tipo de utilizador

O objectivo é permitir que **alunos** sejam utilizadores reais em `auth.users` (`tipo = 'aluno'`), com autenticação JWT unificada e acesso ao portal escolar. Para isso, é necessário separar claramente:

- **`tipo`**: *quem é* o utilizador (`superadmin`, `funcionario`, `aluno`, `encarregado`).
- **`escopo`**: *onde pode actuar* no caso de funcionários (`erp`, `escola`, `ambos`).

### Problemas detectados

1. **Semântica diferente no mesmo sítio:** `tipo` identifica *quem é* o utilizador; `escopo` identifica *onde pode actuar*. São conceitos ortogonais.
2. **Escopo global vs. por tenant:** Um utilizador `funcionario` pode pertencer a vários tenants. O escopo `erp`/`escola`/`ambos` é uma característica do **vínculo** ao tenant, não do utilizador em si.
3. **`superadmin` e `aluno` com escopo:** Superadmins e alunos não têm vínculo de âmbito ERP/Escola, pelo que `escopo` não se aplica. Actualmente o campo é preenchido com `erp` por default, o que é conceptualmente incorrecto.
4. **Dificuldade de evolução:** Adicionar `aluno` ou `encarregado` como tipos de utilizador internos torna o campo `escopo` confuso e obriga a excepções.

---

## Proposta

### 1. `tipo` permanece em `auth.users`

Define o tipo de actor na plataforma. Passa a incluir `aluno` (e opcionalmente `encarregado`):

```sql
ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check,
  ADD CONSTRAINT users_tipo_check
    CHECK (tipo IN ('superadmin', 'funcionario', 'aluno'));
```

> Futuro: `encarregado` pode ser adicionado da mesma forma.

### 2. `escopo` move-se para `auth.memberships`

O escopo é uma propriedade do vínculo entre o utilizador e o tenant:

```sql
ALTER TABLE auth.memberships
  ADD COLUMN IF NOT EXISTS escopo VARCHAR(20) NOT NULL DEFAULT 'erp'
  CONSTRAINT memberships_escopo_check
    CHECK (escopo IN ('erp', 'escola', 'ambos'));
```

Regras:

- Só se aplica a `funcionario`.
- `superadmin` e `aluno` não têm `membership` de funcionário, logo não têm `escopo`.
- Um utilizador `funcionario` pode ter escopos diferentes em tenants diferentes.

### 3. Remove `escopo` de `auth.users`

Após migração dos dados:

```sql
ALTER TABLE auth.users DROP COLUMN IF EXISTS escopo;
```

---

## Migration de transição

```sql
-- 1. Adicionar escopo na memberships
ALTER TABLE auth.memberships
  ADD COLUMN IF NOT EXISTS escopo VARCHAR(20) NOT NULL DEFAULT 'erp'
  CONSTRAINT memberships_escopo_check
    CHECK (escopo IN ('erp', 'escola', 'ambos'));

-- 2. Migrar escopo de users para memberships (apenas funcionários activos)
UPDATE auth.memberships m
   SET escopo = COALESCE(NULLIF(u.escopo, ''), 'erp')
  FROM auth.users u
 WHERE m.user_id = u.id
   AND u.tipo = 'funcionario';

-- 3. Ajustar casos especiais: superadmins ou alunos com membership forçam 'ambos'
UPDATE auth.memberships m
   SET escopo = 'ambos'
  FROM auth.users u
 WHERE m.user_id = u.id
   AND u.tipo IN ('superadmin', 'aluno');

-- 4. Remover escopo de users
ALTER TABLE auth.users DROP COLUMN IF EXISTS escopo;
```

---

## Alterações no backend (Go)

### Login e refresh (`modules/auth/handlers/auth.go`)

Actualmente:

```go
SELECT u.id, COALESCE(m.tenant_id, 0), u.nome, u.password_hash, u.estado, u.tipo, COALESCE(NULLIF(u.escopo, ''), 'erp')
  FROM users u
  LEFT JOIN auth.memberships m ON m.user_id = u.id
 WHERE u.email = LOWER($1)
```

Passa a:

```go
SELECT u.id, COALESCE(m.tenant_id, 0), u.nome, u.password_hash, u.estado, u.tipo,
       COALESCE(NULLIF(m.escopo, ''), 'erp')
  FROM users u
  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
 WHERE u.email = LOWER($1)
```

> Importante: se houver múltiplas memberships, o login deve usar a membership ativa (ou a principal). Se não existir membership ativa e for `superadmin` ou `aluno`, `tenant_id = 0` e `escopo = ''`.

### JWT

```go
func (h *Handler) signAccess(userID, tenantID int64, tipo, escopo string) (string, error) {
    if escopo == "" && tipo == "funcionario" {
        escopo = "erp"
    }
    claims := jwt.MapClaims{
        "sub":    userID,
        "tid":    tenantID,
        "tipo":   tipo,
        "escopo": escopo, // vazio para superadmin
        ...
    }
}
```

### Middleware de escopo (`middleware/auth.go`)

O middleware `escopoPermitidoParaPath` continua igual, mas o `escopo` vem do JWT. Para superadmin, o middleware pode ignorar a verificação de escopo (como já faz para permissões).

### CRUD de utilizadores (`modules/auth/handlers/utilizadores.go`)

- Criar utilizador: o `escopo` passa a ser gravado na `membership`, não no `users`.
- Listar utilizadores: `escopo` vem de `m.escopo`.
- Ver detalhes: `escopo` vem de `m.escopo`.
- Actualizar: permitir alterar `escopo` apenas da membership do tenant actual.

### Models RBAC

`UserAccess.Escopo` continua a existir, mas é carregado a partir da membership ativa.

---

## Alterações no frontend (PHP)

### Formulário de utilizadores

O campo `escopo` continua no formulário, mas é enviado para o backend como parte do payload de criação/edição. O backend decide onde gravar.

### Session

`AdminSession::escopo()` continua a ler da resposta do login (`body['escopo']`). Nenhuma mudança visível no frontend.

---

## Vantagens da proposta

1. **Modelo mais correcto conceptualmente:** `escopo` é do vínculo, não do utilizador.
2. **Multi-tenant limpo:** um utilizador pode ser `erp` num tenant e `escola` noutro.
3. **Superadmin sem escopo:** não há valor forçado/incoerente.
4. **Evolução futura:** facilita adicionar tipos `aluno`, `encarregado`, etc., sem confusão com escopo.
5. **RBAC mais preciso:** permissões e escopo ficam ambos na membership.

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Login com múltiplas memberships | Usar `m.ativo = true` e, no futuro, adicionar `membership_id` ao token ou fluxo de selecção de tenant. |
| Alunos autenticam-se via portal separado | Manter tabela `gestao_escolar.portal_sessions` durante transição; unificar gradualmente para `auth.users` + JWT. |
| Dados existentes | Migration migra `users.escopo` para `memberships.escopo` antes de remover a coluna. |
| Código espalhado | Grep por `u.escopo`/`users.escopo` e actualizar todos os pontos. |
| Frontend | O campo continua visível; apenas o destino no backend muda. |

---

## Checklist de implementação

- [ ] Criar migration para adicionar `escopo` em `auth.memberships`.
- [ ] Migrar dados de `users.escopo` para `memberships.escopo`.
- [ ] Remover `escopo` de `auth.users`.
- [ ] Actualizar login/refresh para ler `m.escopo`.
- [ ] Actualizar CRUD de utilizadores.
- [ ] Actualizar models e testes RBAC.
- [ ] Actualizar frontend (se necessário).
- [ ] Testar login com `superadmin`, `erp`, `escola`, `ambos`.
