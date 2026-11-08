# Análise — abertura e fechamento de caixa

**Backend analisado:** `mobile/backend`  
**Data:** 6 de setembro de 2026  
**Decisão:** a funcionalidade é viável, mas requer a criação de um módulo de caixa e a evolução do modelo de pagamentos; não deve ser tratada apenas como um campo adicional em `sales`.

## 1. Situação atual

O backend PHP possui uma base útil para um PDV simples:

- isolamento por empresa através de `tenant_id`;
- utilizador que registou a venda em `sales.user_id`;
- valores monetários guardados em cêntimos (`total_cents` e `unit_price_cents`);
- vendas imutáveis: o cancelamento altera o estado para `cancelled`, em vez de apagar o histórico;
- transação SQL que desconta stock e grava a venda;
- suporte a SQLite, MySQL, PostgreSQL, SQL Server e MongoDB.

Contudo, não existem no modelo nem na API:

- caixa físico/lógico;
- turno ou sessão de caixa;
- loja ou terminal de venda;
- fundo de troco;
- sangria, suprimento ou ajuste;
- contagem física e divergência no fechamento;
- aprovação de divergência;
- pagamento dividido ou uma transação de pagamento por venda.

Hoje, `POST /api/sales` aceita uma venda para qualquer utilizador autenticado do tenant e não verifica se há caixa aberto. A tabela `sales` contém somente um `payment_method`, logo não permite identificar várias parcelas ou estados de pagamentos eletrónicos.

Isto já permite que vários utilizadores com papel `user`, pertencentes ao mesmo tenant, registem vendas em paralelo: cada registo guarda o operador em `sales.user_id` e a empresa em `sales.tenant_id`. O módulo de caixa deve preservar esta separação, sem tornar o caixa "coletivo" por acidente.

## 2. Conclusão de viabilidade

É tecnicamente viável implementar abertura e fechamento de caixa sobre a arquitetura atual. A separação Controller → Service → Repository, as interfaces de repositório e o uso de transações SQL permitem acrescentar o domínio de forma consistente.

O requisito, porém, afeta o fluxo de venda: uma venda concluída deve estar vinculada a uma sessão aberta e os seus efeitos financeiros devem ser persistidos na mesma operação da venda. Criar apenas endpoints de abertura/fechamento sem alterar o checkout produziria relatórios inconsistentes.

Para operações financeiras reais, a implementação recomendada é em MySQL, PostgreSQL ou SQL Server. O repositório Mongo atual declara consistência *best-effort* entre desconto de stock e gravação da venda; para caixa, isso só é aceitável com transações Mongo em replica set e uma estratégia explícita de recuperação.

## 3. Modelo de dados proposto

### 3.1 `cash_registers`

Representa o caixa físico ou lógico utilizado no atendimento.

| Campo | Finalidade |
|---|---|
| `id` | Identificador do caixa |
| `tenant_id` | Isolamento por empresa |
| `terminal_id` | Terminal/dispositivo, quando existir |
| `name` / `code` | Identificação operacional |
| `active` | Permite desativar sem apagar histórico |
| `created_at`, `updated_at` | Auditoria básica |

Enquanto não houver lojas e terminais, é possível iniciar com um caixa por tenant. Isto é um MVP, não o modelo definitivo: dois dispositivos poderiam operar no mesmo caixa sem uma separação física confiável.

### 3.2 `cash_sessions`

Representa o turno iniciado por um operador.

| Campo | Finalidade |
|---|---|
| `id` | Identificador da sessão |
| `tenant_id`, `cash_register_id` | Escopo e caixa usado |
| `opened_by_user_id` | Operador que abriu |
| `opened_at` | Momento de abertura, em UTC |
| `opening_amount_cents` | Fundo de troco inicial em numerário |
| `status` | `open`, `closing_pending_approval`, `closed`, `cancelled` |
| `closed_by_user_id`, `closed_at` | Quem efetivou o fechamento |
| `approved_by_user_id`, `approved_at` | Supervisor, quando houver divergência aprovada |
| `notes` | Observação operacional |

Regra essencial: deve existir no máximo uma sessão com estado `open` ou `closing_pending_approval` por caixa. Em SQL, isto deve ser garantido por transação e bloqueio/índice adequado ao SGBD, não apenas por uma consulta prévia na aplicação.

### Decisão para o comércio analisado: caixa partilhado

O dinheiro fica armazenado num único local e é partilhado pelos vendedores. Portanto, há **uma única sessão aberta por caixa/loja**, mesmo que existam vários utilizadores `user` e dispositivos de venda. O saldo é do caixa da loja, não da conta individual do vendedor.

| Elemento | Comportamento definido |
|---|---|
| Sessão de caixa | Uma sessão `open` por caixa/loja e turno |
| Abertura | Feita uma vez pelo responsável ou primeiro utilizador autorizado |
| Fundo inicial | Valor físico único, contado no local onde o dinheiro fica guardado |
| Vendas | Todos os dispositivos registam vendas na mesma sessão de caixa |
| Saldo esperado | Único e partilhado; soma os movimentos de todos os vendedores |
| Rastreabilidade | Cada venda e movimento mantém `user_id` e, quando existir, `terminal_id`/`device_id` |
| Fechamento | Uma contagem física e um fechamento único para o caixa inteiro |

Os vendedores não abrem caixas paralelos. Depois de a sessão estar aberta, cada dispositivo consulta a sessão ativa daquele caixa e só então permite concluir vendas. O servidor deve validar o vínculo do dispositivo com o caixa e recusar a venda quando não houver sessão `open`.

O relatório deve oferecer simultaneamente dois níveis de leitura:

1. **Consolidado do caixa:** fundo inicial, todas as vendas em dinheiro, sangrias, suprimentos, valor esperado, valor contado e diferença.
2. **Detalhe por vendedor/dispositivo:** vendas e movimentos que cada utilizador registou, sem criar saldos individuais de dinheiro.

Exemplo de apuramento partilhado:

```text
Fundo inicial:             1.000 MT
Venda Ana (dispositivo A): 2.000 MT
Venda Bruno (B):           1.500 MT
Venda Carla (C):             500 MT
Sangria feita por Ana:    -3.000 MT
-----------------------------------
Saldo esperado no caixa:   2.000 MT
```

Embora Ana tenha registado a sangria e cada vendedor tenha vendas próprias, os `2.000 MT` são o saldo de um único dinheiro físico. Se os vendedores terminarem em horários diferentes, saem do sistema/dispositivo, mas a sessão permanece aberta até o responsável contar e fechar o caixa partilhado.

### 3.3 `cash_movements`

Livro-razão imutável do caixa. Não se deve recalcular o histórico alterando movimentos antigos.

| Campo | Finalidade |
|---|---|
| `id`, `tenant_id`, `cash_session_id` | Identificação e vínculo ao turno |
| `type` | `opening`, `sale_cash`, `supply`, `withdrawal`, `adjustment`, `sale_reversal`, `closing` |
| `payment_method` | Inicialmente `cash`; evolui para cada meio de pagamento |
| `amount_cents` | Sempre inteiro; usar sinal ou direção definida de forma uniforme |
| `sale_id` | Referência da venda ou do cancelamento, quando aplicável |
| `reason` | Obrigatório em sangria, suprimento e ajuste |
| `created_by_user_id`, `approved_by_user_id` | Rastreabilidade e aprovações |
| `created_at` | Data/hora UTC |

O saldo esperado em dinheiro é calculado a partir dos movimentos: abertura + vendas em dinheiro + suprimentos − sangrias ± ajustes − estornos/devoluções.

### 3.4 `cash_countings`

Guarda a contagem declarada no fechamento, uma linha por meio de pagamento.

| Campo | Finalidade |
|---|---|
| `id`, `cash_session_id` | Vínculo com a sessão |
| `payment_method` | Meio contado/conferido |
| `expected_cents` | Calculado no servidor |
| `counted_cents` | Informado pelo operador sem prévia do esperado |
| `difference_cents` | `counted_cents - expected_cents` |

## 4. Evolução necessária em vendas e pagamentos

Antes de suportar cartões, carteira móvel ou pagamento misto, criar `sale_payments`:

| Campo | Finalidade |
|---|---|
| `id`, `sale_id`, `cash_session_id` | Liga pagamento, venda e caixa |
| `method` | `cash`, `card`, `transfer`, `mpesa`, etc. |
| `amount_cents` | Valor da parcela |
| `status` | `pending`, `approved`, `declined`, `cancelled`, `refunded` |
| `external_reference` | Referência de TPA/gateway, se existir |
| `idempotency_key` | Evita cobrança ou lançamento duplicado |
| `created_at`, `updated_at` | Auditoria |

No MVP exclusivamente em dinheiro, pode-se manter temporariamente `sales.payment_method`, desde que a venda grave também um `cash_movement` atómico. Para uma implementação completa, `sale_payments` deve substituir a dependência de um único método na venda.

## 5. Fluxos e regras de negócio

### Abertura

1. Operador seleciona o caixa/terminal e informa o fundo de troco.
2. Servidor valida autenticação, permissão, escopo e inexistência de sessão concorrente aberta.
3. Cria `cash_session` com estado `open` e um movimento `opening` na mesma transação.
4. Devolve o comprovativo de abertura.

O utilizador que abre não precisa ser `admin`: no MVP, o papel `user` autorizado pode abrir o turno partilhado. Um `admin` fica responsável por configuração de caixas, aprovação de diferenças e exceções. Os restantes utilizadores `user` apenas usam a sessão já aberta; não podem abrir outra sessão para o mesmo caixa.

### Venda

1. Cliente envia a venda identificando a sessão de caixa ativa; idealmente o servidor a resolve pelo caixa/terminal autenticado.
2. Servidor verifica que a sessão está `open`.
3. Servidor confirma que a sessão é a sessão partilhada aberta para o caixa/loja do dispositivo autenticado.
4. Na mesma transação: reserva stock, cria a venda, cria pagamentos e movimentos financeiros aprovados.
5. Se qualquer etapa falhar, nada é gravado.

### Sangria e suprimento

1. Operador informa valor e motivo.
2. Servidor exige sessão aberta e permissão correspondente.
3. Acima de um limite configurável, a operação fica pendente de aprovação ou exige aprovação no momento.
4. O sistema grava um movimento imutável e atualiza somente o saldo derivado, se houver um para consulta rápida.

### Fechamento

1. Operador encerra o atendimento e informa valores contados por meio de pagamento, sem receber previamente o total esperado.
2. Servidor bloqueia novas vendas para a sessão durante a conferência.
3. Calcula esperado, contado e diferença no servidor.
4. Sem divergência — ou dentro da tolerância autorizada — grava `closed`.
5. Com divergência que exige supervisão, grava `closing_pending_approval`; um aprovador distinto decide entre fechar ou rejeitar.
6. Uma sessão `closed` não aceita novas vendas, sangrias nem suprimentos.

### Cancelamento de venda

O cancelamento deve gerar movimentos reversos para o caixa e pagamento, não apenas repor stock. Para pagamentos externos, o estorno deve ter estado próprio até a confirmação do provedor.

## 6. Endpoints sugeridos

| Método | Endpoint | Objetivo |
|---|---|---|
| `GET` | `/api/cash-registers` | Listar caixas disponíveis |
| `POST` | `/api/cash-sessions` | Abrir turno de caixa |
| `GET` | `/api/cash-sessions/current` | Consultar sessão aberta do caixa/terminal |
| `GET` | `/api/cash-sessions/{id}` | Consultar sessão e totais parciais |
| `POST` | `/api/cash-sessions/{id}/supplies` | Registar suprimento |
| `POST` | `/api/cash-sessions/{id}/withdrawals` | Registar sangria |
| `POST` | `/api/cash-sessions/{id}/close` | Enviar contagem e solicitar fechamento |
| `POST` | `/api/cash-sessions/{id}/approve-close` | Aprovar/rejeitar divergência |
| `GET` | `/api/cash-sessions/{id}/report` | Relatório detalhado do turno |

## 7. Autorização

O backend atual só possui os perfis globais `admin`, `user` e `super_admin`. Para o MVP, uma regra prática pode permitir abertura, venda, sangria e pedido de fechamento para `user`/`admin`, e aprovação de divergência apenas para `admin`.

O papel `user` não deve ser limitado a uma única venda nem a um único tenant por essa regra. A autorização continua a ser validada no tenant do token. Portanto, vários `user` do mesmo tenant podem vender simultaneamente na sessão de caixa partilhada, e cada venda preserva o respetivo `user_id` e identificador de dispositivo.

Para atender ao requisito completo, evoluir para permissões por ação e escopo:

- `cash.open`;
- `cash.close`;
- `cash.close.approve`;
- `cash.withdrawal.create` e `cash.withdrawal.approve`;
- `cash.supply.create` e `cash.supply.approve`;
- `report.cash.view`.

As permissões precisam ser limitadas por tenant e, posteriormente, por loja, terminal e caixa.

## 8. Impacto técnico no backend

Os seguintes pontos serão alterados:

1. Schemas SQL (`schema.sqlite.sql`, `schema.mysql.sql`, `schema.postgresql.sql`, `schema.sqlserver.sql`) e índices Mongo no `InstallerService`.
2. Models, DTOs, enums de estado/tipo e interfaces de repositório para caixa e pagamentos.
3. Implementações `Pdo*` e `Mongo*` correspondentes, incluindo transações SQL.
4. Registos no `RepositoryFactory` e injeção de dependências em `App`.
5. `SaleService` e `PdoSaleRepository`, para exigir sessão aberta e criar o lançamento financeiro na mesma transação.
6. Novos `CashSessionService` e `CashSessionController`.
7. Rotas, OpenAPI, `API.md` e coleção Postman.
8. Testes de transação, autorização, concorrência, isolamento entre tenants e divergência.

Como o instalador usa `CREATE TABLE IF NOT EXISTS`, instalações já existentes precisam de migrações versionadas com `ALTER TABLE`/criação aditiva; apenas editar os schemas não atualiza bases de dados já instaladas.

## 9. Plano recomendado

### Entrega 1 — Caixa em dinheiro

- Criar caixa e sessão de caixa.
- Abrir e fechar com fundo de troco, contagem cega e diferença.
- Exigir sessão aberta para venda em dinheiro.
- Criar movimentos de abertura, venda, sangria, suprimento e cancelamento.
- Permitir aprovação de divergência por administrador.
- Emitir relatório por sessão.

### Entrega 2 — Pagamentos e operação completa

- Criar `sale_payments` e pagamentos divididos.
- Tratar cartão, carteiras móveis, referências externas, estornos e idempotência.
- Criar lojas, terminais e caixa por terminal.
- Substituir papéis simples por permissões granulares e escopadas.
- Implementar auditoria, exportação, sincronização offline e reconciliação.

## 10. Critérios mínimos de aceite

- Não é possível concluir uma venda em dinheiro sem sessão aberta.
- Não podem existir duas sessões abertas no mesmo caixa.
- Vários utilizadores `user` do mesmo tenant podem vender em paralelo na única sessão partilhada do caixa/loja.
- O relatório da sessão identifica o operador da abertura e o autor de cada venda, sangria, suprimento e fechamento.
- Cada venda em dinheiro gera exatamente um movimento financeiro vinculado à sessão.
- Sangria e suprimento guardam valor, motivo, operador e aprovação quando aplicável.
- O fechamento compara total esperado e contado por método, sem aceitar valores calculados pelo cliente como autoridade.
- Após `closed`, novas vendas e movimentos são recusados.
- Cancelar uma venda cria o movimento financeiro inverso e mantém o histórico.
- Um tenant não pode consultar ou alterar sessões, movimentos ou relatórios de outro tenant.
- Reenvios de comandos financeiros não duplicam vendas ou movimentos.

## 11. Riscos e decisões pendentes

1. Confirmar se o primeiro lançamento será apenas numerário ou incluir M-Pesa, cartão e e-Mola.
2. Definir se cada dispositivo terá um caixa exclusivo ou se vários terminais podem partilhar um caixa.
3. Definir limites e responsáveis pela aprovação de sangrias, suprimentos e diferenças.
4. Definir tolerância permitida para sobra/falta e o destino contabilístico da diferença.
5. Definir política de operação offline e reconciliação, antes de permitir uso financeiro sem conectividade.
6. Confirmar a base de dados de produção; para fluxo financeiro, preferir um SGBD relacional transacional.

## Referências internas

- `mobile/backend/src/Repositories/PdoSaleRepository.php`
- `mobile/backend/src/Repositories/MongoSaleRepository.php`
- `mobile/backend/src/Services/SaleService.php`
- `mobile/backend/routes/api.php`
- `mobile/backend/database/schema.*.sql`
- `Especificação Técnica — Aplicativo PDV Mobile.md` — requisitos RF-050 a RF-055, RN-013, RN-014 e RN-016.
