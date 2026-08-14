# Análise do Backend Go factPro vs Modelo de Identidade Nexora

> **Referência:** `D:\projecto\e-258tech\2026\PayCore\Analise_Fluxo_Autenticacao_vs_Modelo_Nexora.md`  
> **Backend analisado:** `D:\projecto\e-258tech\2026\factPro\backend`  
> **Data:** 2026-08-10

---

## 1. Resumo Executivo

O backend Go já possui **boa parte da infraestrutura** necessária para o modelo recomendado:

- Existe separação conceitual entre **usuário**, **funcionário** e **terminal**.
- O terminal possui uma **conta técnica sintética** em `auth.users` (`pos.pos_terminals.user_id`), com cargo e permissão restritos (`pos:operar_pos`).
- Existe endpoint de **ativação técnica do terminal** (`POST /api/pos/login` com `tipo=terminal`).
- Existe endpoint de **login do operador por PIN** dentro do terminal (`POST /api/pos/login-operador`).
- A gestão administrativa de terminais (`/api/pos/terminais`) está corretamente isolada da operação POS.

**No entanto, o backend ainda permite e, em alguns pontos, incentiva o fluxo incorreto identificado no mobile PayCore:** operações de caixa e venda podem ser executadas com o **token técnico do terminal**, sem exigir o token pessoal do operador humano. Além disso, `funcionario_id` ainda **não é gravado** nem na sessão (`pos_sessions`) nem na venda (`pos_sales`), e não existe controle explícito de quais funcionários podem operar cada terminal.

---

## 2. Análise por Arquivo/Componente

### 2.1 `backend/internal/modules/auth/handlers/pos_login.go` — Login de Terminal

#### O que faz hoje
- `POST /api/pos/login` aceita `tipo=terminal` com `codigo_terminal`, `activation_code` e `tenant_slug`.
- Procura o terminal em `pos.pos_terminals`, valida o `activation_code` via `bcrypt` contra o `password_hash` da conta técnica (`<codigo>@terminal.internal`).
- Se válido e ativo, emite um token de longa duração (**30 dias**) com escopo `erp` e permissões do cargo `Terminal POS` (`pos:operar_pos`).
- O refresh revalida se o terminal ainda está ativo antes de reemitir.

#### Alinhamento
| Aspeto | Estado |
|--------|--------|
| Token técnico do terminal | ✅ Implementado |
| Validade longa para máquina | ✅ Implementado |
| Revalidação no refresh | ✅ Implementado |
| Conta técnica com permissões mínimas | ✅ Apenas `pos:operar_pos` |

#### Gaps
1. **O token de terminal é funcionalmente equivalente ao token de um operador humano.** Não há nada que impeça o mobile de usar esse token para abrir sessão, vender, fechar caixa, etc. O backend não distingue "token de máquina" vs "token de pessoa" nas rotas POS.
2. **O email sintético `<codigo>@terminal.internal` pode colidir entre tenants.** O `codigo` é único apenas por tenant, mas `auth.users.email` é globalmente único (violando RNF-ID-05 do modelo).

#### Sugestão
- Introduzir uma claim `terminal_id` no token de terminal e rejeitar esse token nas rotas de operação humana (sessão, venda, movimento), ou criar um middleware `RequireHumanOperator` que exija que `AuthUser.Tipo != 'funcionario'` com `terminal_id` na claim.
- Tornar o email técnico único globalmente, ex.: `<codigo>.<tenant_id>@terminal.internal` ou usar UUID.

---

### 2.2 `backend/internal/modules/auth/handlers/pos_pin_login.go` — Login de Operador por PIN

#### O que faz hoje
- `POST /api/pos/login-operador` exige um chamador autenticado (tipicamente o terminal).
- Recebe apenas `pin`.
- Procura dentro do `tenant_id` do chamador todos os `auth.user_auth_codes` ativos do tipo `pin`.
- Compara cada hash até encontrar o dono.
- Resolve `funcionario_id` via `funcionario.NewService(h.db).PorUserID(...)`.
- Emite tokens pessoais do operador via `issueFuncionarioTokens`.

#### Alinhamento
| Aspeto | Estado |
|--------|--------|
| Login por PIN sem email | ✅ Implementado |
| Restrito ao tenant do terminal | ✅ Implementado |
| Resolve `funcionario_id` no login | ✅ Implementado |

#### Gaps
1. **Não valida se o operador está autorizado naquele terminal.** Qualquer funcionário do tenant com PIN ativo pode gerar um token pessoal a partir de qualquer terminal ativo (viola RF-ID-08 do modelo).
2. **A rota está dentro do grupo `/api/pos` protegido por `pos:operar_pos`.** Isso funciona para o terminal, mas se um operador humano autenticado chamar essa rota, ela também passa. Não é um erro grave, mas a semântica é "trocar operador no terminal", não "qualquer um logar outro".

#### Sugestão
- Adicionar validação opcional/graduada contra `pos.terminal_funcionarios` (quando existir).
- Incluir no response do `login-operador` o `terminal_id` (e talvez `funcionario_id`) para o app saber o contexto.

---

### 2.3 `backend/internal/modules/pos/handlers/pos.go` — Sessões e Vendas POS

#### O que faz hoje

**Sessões (`AbrirSessao`):**
```go
user := mw.GetUser(r)
var body struct {
    TerminalID    int64   `json:"terminal_id"`
    OpeningAmount float64 `json:"opening_amount"`
}
```
- Valida se o terminal existe e está ativo no tenant.
- Verifica se já existe sessão aberta para `user.ID` (o ID do token).
- Insere `pos_sessions` com `tenant_id`, `terminal_id`, `user_id` (do token).
- **Não resolve nem grava `funcionario_id`.**

**Vendas (`CriarVenda`):**
- Recebe `pos_session_id`, itens e pagamentos.
- Busca `terminal_id` da sessão aberta.
- Insere `pos_sales` com `tenant_id`, `pos_session_id`, `terminal_id`, `created_by = user.ID`.
- **Não grava `funcionario_id`.**

**Fecho (`FecharSessao`):**
- Atualiza a sessão com `closing_amount`, `contagem_notas`, `justificativa_diferenca`.

#### Alinhamento
| Aspeto | Estado |
|--------|--------|
| `terminal_id` no body de abertura | ✅ Implementado |
| `terminal_id` propagado para a venda via sessão | ✅ Implementado |
| `funcionario_id` na sessão | ❌ Não existe |
| `funcionario_id` na venda | ❌ Não existe |
| Exigência de token pessoal do operador | ❌ Não existe |

#### Gaps Críticos
1. **Abertura de sessão com token de terminal registra a conta técnica como operador.** O `user_id` gravado em `pos_sessions` será o da conta técnica do terminal, não do funcionário humano.
2. **Não existe validação de que o `user.ID` é um funcionário ativo.** Um usuário comum sem vínculo em `rh.funcionarios` pode abrir sessão (viola RF-ID-08).
3. **Não existe validação de autorização no terminal.** Se o operador for um funcionário, não se verifica se ele pode usar aquele terminal.
4. **Vendas não identificam o operador humano.** Apenas `created_by` (user_id do token) e `terminal_id` são gravados. Relatórios de comissão e auditoria de RH precisam de `funcionario_id` imutável.
5. **Regra de unicidade de sessão aberta é por `user_id`, não por terminal.** O modelo exige que não haja duas sessões abertas no mesmo terminal; hoje só se impede uma sessão aberta por usuário.

#### Sugestão
1. Adicionar coluna `funcionario_id` em `pos_sessions` e em `pos_sales`.
2. Em `AbrirSessao`:
   - Resolver `funcionario_id` a partir de `user.ID` no tenant.
   - Validar que o funcionário está ativo e possui `pos:operar_pos`.
   - Validar autorização no terminal (`pos.terminal_funcionarios` quando existir).
   - Verificar se já não existe sessão aberta para o mesmo `terminal_id`.
   - Gravar `funcionario_id` na sessão.
3. Em `CriarVenda`:
   - Validar que a sessão pertence ao operador autenticado (token pessoal).
   - Copiar `funcionario_id` da sessão para `pos_sales.funcionario_id`.
   - Gravar `created_by = user.ID` (conta) e `funcionario_id` (pessoa/operador).
4. Em `FecharSessao`:
   - Garantir que quem fecha é o mesmo operador da sessão (ou supervisor).

---

### 2.4 `backend/internal/router/router.go` — Proteção de Rotas e Permissões

#### O que faz hoje
- `/api/pos/login` e `/api/pos/refresh` são **públicos** — correto para ativação.
- `/api/pos` agrupa rotas protegidas por `RequireAuth`, `EnforceTenantHost`, `AuditModule` e `RequireLicencaAtiva`.
- Dentro de `/api/pos`:
  - Operações de terminal (sessões, vendas, pagamentos, sync, login-operador) exigem `pos:operar_pos`.
  - Gestão de terminais exige `pos:gerir_terminais`.
  - Catálogo exige `pos:gerir_catalogo`.
  - Descontos exigem `pos:gerir_descontos`.
  - Relatórios exigem `pos:relatorios`.
  - Cancelamento/estorno/movimentos exigem `pos:supervisionar_pos`.

#### Alinhamento
| Aspeto | Estado |
|--------|--------|
| Separação administrativa vs operacional | ✅ `gerir_terminais` vs `operar_pos` |
| Login e refresh públicos | ✅ Correto |
| Operações POS protegidas por permissão | ✅ Parcialmente |

#### Gaps
1. **A permissão `pos:operar_pos` é atribuída tanto à conta técnica do terminal quanto a operadores humanos.** Isso faz com que o backend não consiga distinguir se uma venda foi feita por uma pessoa autenticada ou pela máquina.
2. **Não há rota/middleware específico para "operador humano autenticado".**
3. **A rota `/api/pos/login-operador` está dentro do grupo `operar_pos`.** Embora funcione, a semântica ideal seria que o próprio terminal (com token técnico) pudesse chamar essa rota sem precisar de `operar_pos`, pois trata-se de autenticação, não operação de caixa.

#### Sugestão
- Criar uma claim `terminal_id` no token de terminal e um middleware/helper `IsTerminalToken()` / `RequireHumanOperator()`.
- Proteger `POST /api/pos/sessoes`, `POST /api/pos/sales`, `POST /api/pos/sessoes/{id}/fechar`, `POST /api/pos/sessoes/{id}/movimentacoes` com `RequireHumanOperator` (além de `operar_pos`).
- Considerar `POST /api/pos/login-operador` como rota de autenticação acessível apenas por token de terminal (não por token de operador humano).

---

### 2.5 `backend/internal/middleware/auth.go` — Contexto de Autenticação

#### O que faz hoje
```go
type AuthUser struct {
    ID           int64
    TenantID     int64
    SessionID    int64
    MembershipID int64
    Tipo         string    // "superadmin" | "funcionario"
    Escopo       string    // "erp" | "escola"
    ReauthAt     time.Time
}
```

- `RequireAuth` valida o JWT, verifica sessão ativa em `auth.sessions` e coloca `AuthUser` no contexto.
- `RequirePermission`/`RequirePermissionAny` verificam RBAC.
- Não há distinção entre token de terminal e token de pessoa.

#### Alinhamento
| Aspeto | Estado |
|--------|--------|
| Contexto de usuário autenticado | ✅ Implementado |
| Verificação de sessão na BD | ✅ Implementado |
| Diferenciação terminal vs humano | ❌ Não existe |
| `funcionario_id` no contexto | ❌ Não existe |

#### Gaps
1. **O middleware não carrega `funcionario_id`.** Todos os handlers POS precisariam resolver manualmente `rh.funcionarios` a cada request.
2. **Não existe distinção de "token de máquina".** O tipo `funcionario` abrange tanto operadores humanos quanto a conta técnica do terminal.

#### Sugestão
- Adicionar `TerminalID *int64` e `FuncionarioID *int64` a `AuthUser` (opcionais).
- Popular esses campos no token de terminal (`TerminalID`) e no login de operador (`FuncionarioID`), respectivamente.
- Criar helper `mw.IsTerminalToken(r)` para recusar operações que exijam operador humano.

---

### 2.6 Migrations Relacionadas a POS, Terminais e Permissões

#### O que existe hoje
| Migration | Conteúdo relevante |
|-----------|-------------------|
| `archive/20260629000013_pos.up.sql` | Cria `pos_terminals`, `pos_sessions`, `pos_sales`, `pos_sale_items`, `pos_sale_payments`, `pos_catalog_items`. `pos_sessions` tem `terminal_id` e `user_id`; `pos_sales` tem `terminal_id` e `created_by`. |
| `20260724090001_pos_terminals_user_id.up.sql` | Adiciona `pos_terminals.user_id` (conta técnica) e FK para `auth.users`. |
| `20260808150000_pos_caixa_detalhado.up.sql` | Adiciona `pos_sessions.contagem_notas`, `justificativa_diferenca` e cria `pos_cash_movements`. |
| `20260808180000_pos_supervisor_permissions.up.sql` | Cria permissão `pos:supervisionar_pos` e cargos padrão (`Supervisor POS`, `Gerente de Loja`). |
| `20260727093000_permissoes_cargos_padrao_finas.up.sql` | Atribui `pos:gerir_terminais`, `pos:operar_pos`, etc., aos cargos padrão. |

#### Alinhamento
| Aspeto | Estado |
|--------|--------|
| `pos_terminals.user_id` | ✅ Implementado |
| `pos_sessions.terminal_id` + `user_id` | ✅ Implementado |
| `pos_sales.terminal_id` + `created_by` | ✅ Implementado |
| `pos_sessions.funcionario_id` | ❌ Ausente |
| `pos_sales.funcionario_id` | ❌ Ausente |
| `pos.terminal_funcionarios` | ❌ Ausente (apenas proposta no modelo) |
| Garantia de que conta técnica não entra em `rh.funcionarios` | ⚠️ Não há constraint/trigger |

#### Gaps
1. **Não há coluna `funcionario_id` nas tabelas de sessão e venda.** Isso impede rastreabilidade imutável do operador humano.
2. **Não existe `pos.terminal_funcionarios`.** Não é possível restringir quais funcionários podem operar cada terminal.
3. **Não há constraint garantindo que `pos_terminals.user_id` não tenha correspondência em `rh.funcionarios`.** A conta técnica pode, por engano, ser ligada a um funcionário de RH.

#### Sugestão
1. Nova migration:
   ```sql
   ALTER TABLE pos.pos_sessions ADD COLUMN funcionario_id BIGINT REFERENCES rh.funcionarios(id);
   ALTER TABLE pos.pos_sales ADD COLUMN funcionario_id BIGINT REFERENCES rh.funcionarios(id);
   CREATE INDEX idx_pos_sessions_funcionario ON pos.pos_sessions(funcionario_id);
   CREATE INDEX idx_pos_sales_funcionario ON pos.pos_sales(funcionario_id);
   ```
2. Nova migration para `pos.terminal_funcionarios` conforme proposta do modelo.
3. Adicionar constraint/trigger para impedir que `pos_terminals.user_id` seja também `rh.funcionarios.user_id` (ou pelo menos um teste automatizado).

---

## 3. Tabela Resumo de Gaps e Correções

| # | Gap | Onde | Impacto | Correção recomendada |
|---|-----|------|---------|----------------------|
| 1 | Token de terminal pode operar POS como se fosse operador humano | `pos_login.go`, `auth.go`, rotas `/api/pos/*` | Vendas registradas sob identidade da máquina; viola RF-ID-07/09 | Adicionar claim `terminal_id` e middleware `RequireHumanOperator` nas rotas de operação |
| 2 | `funcionario_id` não é gravado na sessão | `pos.go` `AbrirSessao` | Impossível rastrear operador humano de forma imutável | Adicionar coluna `funcionario_id` em `pos_sessions` e gravá-lo na abertura |
| 3 | `funcionario_id` não é gravado na venda | `pos.go` `CriarVenda` | Relatórios de comissão/auditoria comprometidos | Adicionar coluna `funcionario_id` em `pos_sales` e copiar da sessão |
| 4 | Abrir sessão não exige funcionário ativo | `pos.go` `AbrirSessao` | Usuários sem vínculo RH podem operar caixa | Resolver `funcionario_id` e validar ativo/permissão |
| 5 | Não existe autorização por terminal | Ausência de `pos.terminal_funcionarios` | Qualquer funcionário pode operar qualquer terminal | Criar tabela e validar em `AbrirSessao` |
| 6 | Duas sessões abertas no mesmo terminal são permitidas | `pos.go` `AbrirSessao` | Conflito de operadores no mesmo caixa | Adicionar validação por `terminal_id` + índice único parcial |
| 7 | Email técnico do terminal pode colidir entre tenants | `pos.go` `CriarTerminal` | Conflito de `auth.users.email` | Incluir `tenant_id` ou UUID no email sintético |
| 8 | Conta técnica do terminal pode ser ligada a `rh.funcionarios` | Schema sem constraint | Risco de tratar máquina como pessoa | Adicionar trigger/constraint ou teste |
| 9 | `AuthUser` não carrega `funcionario_id` nem `terminal_id` | `middleware/auth.go` | Cada handler precisa resolver identidade | Enriquecer contexto no login/ativação |
| 10 | `/api/pos/login-operador` não valida autorização no terminal | `pos_pin_login.go` | Qualquer funcionário do tenant pode logar em qualquer terminal | Validar contra `pos.terminal_funcionarios` |

---

## 4. Conclusão

O backend Go **já suporta a ativação técnica do terminal e o login por PIN do operador**, o que é uma base sólida. Contudo, ele **não impõe que operações de caixa sejam feitas exclusivamente com token pessoal do operador humano**, nem **persiste `funcionario_id`** nas sessões e vendas. Esses são os gaps críticos que precisam ser fechados para alinhar o fluxo POS ao modelo de identidade usuário/funcionário/terminal.

### Ordem recomendada de correção

1. **Enriquecer o contexto de autenticação** (`AuthUser`) com `TerminalID` e `FuncionarioID`.
2. **Adicionar colunas `funcionario_id`** em `pos_sessions` e `pos_sales`.
3. **Criar `pos.terminal_funcionarios`** para autorização por terminal.
4. **Adicionar middleware `RequireHumanOperator`** e proteger rotas de operação POS.
5. **Ajustar `AbrirSessao`** para resolver e validar `funcionario_id`.
6. **Ajustar `CriarVenda`** para herdar `funcionario_id` da sessão.
7. **Corrigir email técnico do terminal** para evitar colisão entre tenants.

Nenhum arquivo foi alterado nesta análise.
