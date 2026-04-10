# Modulo Financeiro

Gestao de pagamentos, recebimentos, contas a receber, contas a pagar, fluxo de caixa e orcamentos financeiros.

## Dependencias

- `tesouraria` — `conta_bancaria_id` e `caixa_id` destino das transacoes (`payment_transactions`)
- `gestao-clientes` — `customer_id` em `accounts_receivable`
- `compras` — `supplier_id` em `accounts_payable`
- `contabilidade` — recebe lancamentos via `origem_tipo` / `origem_id`

## Tabelas

| Tabela | Descricao |
| --- | --- |
| `payment_methods` | Meios de pagamento (numerario, TPA, MPesa, transferencia, etc.) |
| `financial_categories` | Arvore de categorias de receitas e despesas |
| `payments` | Recebimentos e pagamentos com meio, categoria e documento de origem |
| `payment_transactions` | Linhas de distribuicao por conta bancaria ou caixa (da tesouraria) |
| `accounts_receivable` | Valores em divida por clientes com valor pendente calculado |
| `accounts_receivable_payments` | Imputacao de pagamentos a contas a receber |
| `accounts_payable` | Valores em divida a fornecedores com valor pendente calculado |
| `accounts_payable_payments` | Imputacao de pagamentos a contas a pagar |
| `financial_budgets` | Orcamento por categoria, ano e mes |
| `cash_flow_entries` | Entradas e saidas de fluxo de caixa (realizadas e previstas) |
| `financial_reports` | Relatorios financeiros gerados (DRE, fluxo, aging) |

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database-financeiro.sql` | Schema completo com tabelas, constraints e indices |
| `api-financeiro.md` | Endpoints REST agrupados por recurso |
| `requisitos.md` | Requisitos funcionais e nao funcionais |
| `uml.md` | Diagramas ERD e fluxos |
