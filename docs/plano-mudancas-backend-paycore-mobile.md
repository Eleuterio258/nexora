# Plano de mudanças no backend (Nexora ERP) para servir a app PayCore Mobile

Data: 2026-07-23
Âmbito: `D:\projecto\e-258tech\2026\factPro\backend` (Go)
Documento complementar a `analise-paycore-mobile-integracao.md` — este ficheiro consolida, com base em verificação direta do código-fonte, o que tem de mudar no backend, por ordem de bloqueio.

---

## Correções face à análise anterior

- **"Nexora-Pay" não é um pacote Go interno.** É um microserviço externo (`NEXORA_PAY_BASE_URL`, hoje `http://nexora-pay:3000`), chamado por um cliente HTTP `nexoraPayClient` **não exportado**, definido dentro de `internal/modules/gestao-escolar/handlers/portal_pagamento.go`. Para o POS o reaproveitar, tem de ser extraído para um pacote partilhado.
- **`CancelarVenda` não tem semântica de estorno com motivo.** Hoje só repõe stock e muda `status` para `'cancelada'`. Não existe campo `reason`/`motivo` no request nem no schema — contrariamente ao que a app espera (`EstornoRequest{reason}`).
- **Multi-tenant provavelmente não precisa de `tenantid.ResolveSaas`.** Esse utilitário só é necessário quando a origem do pedido é autenticada via `hardware.devices` (espaço `empresas.companies.id`). Se o POS autenticar sempre como utilizador humano via `auth.memberships`, o `tenant_id` já vem no espaço `saas.tenants.id` — sem tradução necessária. Só passa a ser relevante se a auth de terminal (item 1) vier a reaproveitar o padrão `hardware.devices`.

---

## 1. Login único — terminal tratado como conta de funcionário (RBAC existente)

**Decisão (2026-07-23)**: em vez de construir autenticação de terminal de raiz (tabela nova + middleware novo), o terminal passa a ser **um registo comum em `auth.users`**, com um **cargo dedicado** no RBAC que já existe para funcionários (`auth.cargos` / `auth.memberships`), com uma única permissão atribuída: `pos:operar_pos` (e, se necessário, `pos:ver_vendas`). Isto elimina a necessidade de tabela e middleware novos — o terminal autentica-se pela **mesma lógica** já usada para utilizadores (`auth.Login`), e fica automaticamente limitado ao que o seu cargo permite, sem precisar de um escopo novo no JWT.

**Isto alinha com a realidade atual da app, não a substitui**: continuam a existir dois momentos de login distintos na UX — o terminal autentica-se uma vez (ecrã `LoginTerminalActivity`, ao configurar o aparelho) e o operador autentica-se a cada turno (ecrã de login de utilizador). Não há fusão de ecrãs nem de fluxos — só a porta de entrada no backend fica única (`POST /api/pos/login`), com um campo `tipo` a indicar qual dos dois momentos está a acontecer, e por baixo os dois ramos chamam a mesma validação de utilizador.

```jsonc
// tipo = "utilizador" — operador humano
{ "tipo": "utilizador", "email": "...", "password": "...", "tenant_slug": "..." }

// tipo = "terminal" — o próprio aparelho, uma vez, na configuração
{ "tipo": "terminal", "codigo_terminal": "...", "activation_code": "..." }
```

Resposta varia consoante `tipo`, mas a forma do envelope é comum:

```jsonc
{ "tipo": "utilizador", "accessToken": "...", "refreshToken": "...", "expiresIn": 900 }
{ "tipo": "terminal", "terminalToken": "...", "terminalRefreshToken": "...", "expiresIn": 2592000 }
```

**Como o RBAC de funcionário funciona hoje (verificado no código, 2026-07-23)** — importante porque muda os detalhes de implementação abaixo:

- Permissão **não é uma string única** `"pos:operar_pos"` — são sempre **dois campos separados**, `modulo` e `acao`, guardados em `auth.permissoes_cargo (cargo_id, modulo, acao)`. A notação `modulo:acao` é só convenção de leitura/documentação, nunca um valor persistido.
- `auth.memberships` liga `user_id` + `tenant_id` + `cargo_id` (mais `escopo`, `papel`, `ativo`). Criar um utilizador (`CriarUtilizador`) **não atribui cargo** — fica `cargo_id = NULL` até uma chamada separada de `AtribuirCargo`.
- `RequirePermission(db, "pos", "operar_pos")` (aplicado no router com `r.Use(...)`/`r.With(...)` nos grupos de `/api/pos/*`) verifica a permissão **a cada pedido**, chamando `LoadUserAccess` — isto faz 3-4 queries SQL (cargo, permissões do cargo, permissões diretas, permissões por tipo). **Não há cache** em memória nem Redis.
- **As permissões não vão no JWT** — o token só tem `sub, tid, mid, tipo, escopo`. Consequência prática boa: atribuir/mudar o cargo da conta-terminal faz efeito no próximo pedido, sem precisar de novo login.

**Passos concretos (tudo com endpoints já existentes, sem schema de permissões novo)**:

1. `POST /api/auth/cargos` `{"nome": "Terminal POS"}` → cria o cargo, devolve `cargo_id`.
2. `PUT /api/auth/cargos/{id}/permissoes` `{"permissoes": [{"modulo":"pos","acao":"operar_pos"}]}` — nota: `DefinirPermissoesCargo` faz **substituição total** (`DELETE` + `INSERT`), não incremento; se o terminal precisar também de `ver_vendas`, incluir os dois pares na mesma chamada.
3. `POST /api/auth/utilizadores` — cria a conta do terminal (email sintético `codigo_terminal + "@terminal.internal"`, password = `activation_code`).
4. `PUT /api/auth/utilizadores/{id}/cargo` `{"cargo_id": ...}` — associa o cargo "Terminal POS" à conta (passo que `CriarUtilizador` não faz sozinho).
5. `pos_terminals` ganha coluna nova `user_id BIGINT REFERENCES auth.users(id)`, ligando o registo administrativo (`codigo`, `warehouse_id`, `caixa_id`) à conta que o autentica — este é o único schema novo necessário.
6. Ajustar `CriarTerminal` (`pos.go`) para encadear os passos 1-5 automaticamente (ou pelo menos 3-5, reaproveitando um cargo "Terminal POS" já criado uma vez por tenant).
7. No handler unificado `POST /api/pos/login`, o ramo `tipo="terminal"` resolve `codigo_terminal` → `pos_terminals.user_id` → chama a mesma validação de utilizador já existente (`auth.Login` internamente), só trocando "email+password" por "email sintético+activation_code". Não há middleware novo — `RequireAuth` já serve.
8. Único ajuste em `signAccess`/`signRefresh`: emitir token com validade mais longa quando a conta é de terminal (30 dias em vez dos minutos habituais de humano) — ex. flag `tipo_conta='terminal'` em `auth.users` ou no próprio cargo.

**Consequência**: o item "escopo `pos`/`mobile_erp` no JWT" deixa de ser necessário — o que restringe o que o terminal pode fazer já não é um escopo amplo (`erp`/`escola`), é a **permissão do cargo** (`pos`, `operar_pos`), que já é granular e já existe no motor de permissões atual. Não há mudança a fazer em `escoposPorTipoEscopo`/`escopoPermitidoParaPath` para este propósito.

**Mudanças**:

- Migração pequena: `pos_terminals.user_id` (nullable, FK para `auth.users`) — único schema novo.
- Seed/dado: cargo "Terminal POS" por tenant, com permissão `(modulo="pos", acao="operar_pos")` via `DefinirPermissoesCargo`.
- Ajustar `CriarTerminal` (`pos.go`) para encadear criação de utilizador + atribuição de cargo + preenchimento de `user_id`.
- Novo handler unificado `Login` (`POST /api/pos/login`) que despacha por `tipo`, mas ambos os ramos acabam por chamar a mesma validação de utilizador já existente em `auth.Login`.
- Pequeno ajuste em `signAccess`/`signRefresh` para emitir validade longa quando a conta é de terminal.
- O endpoint antigo `POST /api/auth/login` **mantém-se** para os restantes clientes do ERP (web admin, etc.) — só a app PayCore passa a falar com `/api/pos/login`.

## 3. Sessão de caixa — já existe, só validar contrato

`AbrirSessao` / `FecharSessao` / `ObterSessaoAtual` já existem em `internal/modules/pos/handlers/pos.go` e cobrem razoavelmente o que a app espera (`GET cash-drawers?status=&terminalId=&limit=`). Trabalho aqui é mapeamento de payload, não construção nova.

## 4. Estorno de venda — falta construir a semântica

`CancelarVenda` (`pos.go`) hoje só repõe stock e marca `status='cancelada'`.

**Mudanças**:
- Adicionar coluna `motivo_cancelamento` a `pos_sales`.
- Aceitar campo `reason`/`motivo` no handler `CancelarVenda` e persistir.

## 5. Pagamento móvel real (M-Pesa/eMola/mKesh) — hoje só enum, sem gateway

`metodosPagamentoValidos` (`pos.go`, linha 41) aceita `numerario, transferencia, tpa, mpesa, emola, outro` — mas é só uma string gravada em `pos_sale_payments.tipo`, **sem chamar nenhum gateway**.

Cliente real existe em `internal/modules/gestao-escolar/handlers/portal_pagamento.go`:
```go
type nexoraPayClient struct { baseURL string; apiKey string }
func (c *nexoraPayClient) post(ctx, path, idempotencyKey string, body any) (map[string]any, int, error)
func (c *nexoraPayClient) get(ctx, path string) (map[string]any, int, error)
```

**Mudanças**:
- Extrair `nexoraPayClient` para pacote partilhado, ex. `internal/pkg/nexorapay`, com `NewClient`, `Post`, `Get` exportados.
- Parametrizar `serviceAccount` (hoje hardcoded `"gestao-escolar"` no handler escolar) para poder passar `"pos"` — a config (`config/config.go`, `NexoraPayServiceAccount`) já suporta isto via env var.
- Chamar o cliente a partir de `CriarVenda` quando o método for `mpesa`/`emola`, tratando resposta assíncrona (webhook ou polling de status, à semelhança de `PortalStatusPagamento`).

## 6. Push token para utilizadores ERP — endpoint em falta, serviço já pronto

`internal/push/push.go` já expõe:
```go
func (s *Service) RegisterToken(ctx context.Context, userID int64, token, platform string) error
```
genérico por `user_id`. Só existe endpoint HTTP hoje para candidatos a emprego: `POST /api/candidatos/push-token` (protegido por `RequireCandidatoAuth`).

**Mudanças**:
- Novo endpoint `POST /api/.../push-token` protegido por `RequireAuth` (ou pelo novo escopo `pos`), chamando `push.RegisterToken` com o `user_id` do JWT.

## 7. Eventos de negócio no WebSocket Hub — sem alterar estrutura

`internal/ws/hub.go` define hoje só eventos de chat/presença/notificação (`EvtMessage`, `EvtTyping`, `EvtNotification`, etc.), sem eventos de venda/pagamento. Já existem `SendToUser`, `BroadcastAll`, `BroadcastRoom`.

**Mudanças**:
- Declarar `EvtVendaCriada = "venda_criada"`, `EvtPagamentoRecebido = "pagamento_recebido"`.
- Exportar (ou envolver) a função `encode` do package `ws` para poder ser chamada a partir de `pos.go`.
- Chamar `hub.SendToUser(userID, encode(ws.EvtVendaCriada, payload))` no fim de `CriarVenda`.

## 8. Descontos — hoje três mecanismos paralelos e desligados

Confirmado no código:
- Desconto por produto: `produtos.product_discounts`, handlers `ListarDescontos`/`CriarDesconto`/`ActualizarDesconto` em `internal/modules/gestao-produtos/handlers/catalogo_ext.go`, rotas `/api/produtos/{id}/descontos`.
- Desconto por cliente: `internal/modules/gestao-clientes/handlers/clientes_api_ext.go`, rotas `/api/clientes/{id}/descontos`.
- Desconto inline por item de venda: campo `desconto_percent`, calculado ad-hoc dentro de `CriarVenda` (`pos.go`), sem referência às duas tabelas acima.

**Mudança** (se a app precisa de um desconto "solto", aplicável na venda, como o PayCore Node já modela): criar entidade nova de desconto POS autónomo (percentagem/valor fixo, min/max, validade) — não é uma simples ligação entre as tabelas existentes, porque elas não se falam hoje.

## 9. Multi-tenant

Ver correção acima — não é necessário `tenantid.ResolveSaas` (`internal/pkg/tenantid/resolve.go`) no fluxo de utilizador humano via `auth.memberships`. Só entra em jogo se a auth de terminal do item 1 vier a reaproveitar o padrão `hardware.devices` (espaço `empresas.companies.id`).

---

## Já pronto, só precisa de mapeamento de campos

| Área | Módulo | Caminho |
|---|---|---|
| Catálogo | `gestao-produtos` | `internal/modules/gestao-produtos/handlers/` — `/api/produtos` |
| Stock | `gestao-stock` | `internal/modules/gestao-stock/handlers/` — `/api/stock` |
| Clientes | `gestao-clientes` | `internal/modules/gestao-clientes/handlers/` — `/api/clientes` |
| Numeração de vendas/faturas | `modulo-faturacao` | `internal/modules/modulo-faturacao/handlers/` — `invoice_series` |

Todos multi-tenant via `mw.GetUser(r).TenantID`, sem mudança estrutural necessária.

---

## Ordem de execução sugerida

1. Item 2 (escopo `pos` no JWT) — trivial, desbloqueia autenticação de utilizador humano no fluxo mobile já hoje.
2. Item 1 (auth de terminal) — maior peça em falta, bloqueia o resto do fluxo POS mobile-first.
3. Item 4 (estorno) e item 8 (descontos) — mudanças de schema pequenas/médias no módulo `pos`.
4. Item 6 (push token) e item 7 (eventos WS) — incrementais, baixo risco.
5. Item 5 (gateway de pagamento real) — maior valor de produto, mas depende de decisão sobre extração do cliente Nexora-Pay para pacote partilhado.
