# Modulo POS — Point of Sale

Gestao de terminais, sessoes de caixa, vendas, pagamentos, devolucoes e reconciliacao de caixa.

## Dependencias

- `gestao-produtos` — `product_id` nas linhas de venda
- `gestao-stock` — baixa de stock no `warehouse_id` do terminal
- `financeiro` — regista recebimentos via `payment_method_id`
- `tesouraria` — `caixa_id` associado ao terminal; reconciliacao no fecho
- `contabilidade` — recebe lancamentos de receita por sessao

## Tabelas

### Configuracao

| Tabela | Descricao |
| --- | --- |
| `pos_terminals` | Terminais com armazem, caixa e impressora associados |

### Sessoes

| Tabela | Descricao |
| --- | --- |
| `pos_sessions` | Sessao de caixa com saldos, totais e diferenca calculada (GENERATED AS STORED) |
| `pos_session_payments` | Resumo de totais por metodo de pagamento no fecho — reconciliacao |

### Vendas

| Tabela | Descricao |
| --- | --- |
| `pos_sales` | Venda com subtotal, desconto total, IVA total, total e troco |
| `pos_sale_items` | Linhas com desconto por linha, IVA por linha e subtotal |
| `pos_payments` | Pagamentos por metodo (suporta divisao multi-metodo) |

### Devolucoes

| Tabela | Descricao |
| --- | --- |
| `pos_returns` | Devolucao com tipo de reembolso (numerario, credito loja, mesmo metodo) |
| `pos_return_items` | Itens devolvidos com referencia ao item original da venda |

### Movimentos

| Tabela | Descricao |
| --- | --- |
| `pos_cash_movements` | Entradas e saidas manuais de caixa com motivo obrigatorio |

## Colunas Calculadas

| Coluna | Tabela | Formula |
| --- | --- | --- |
| `diferenca_caixa` | `pos_sessions` | `saldo_final_declarado - saldo_final_calculado` |
| `total_liquido` | `pos_session_payments` | `total_vendas - total_devolucoes` |

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database-pos.sql` | Schema completo — 9 tabelas, constraints, indices |
| `api-pos.md` | Endpoints REST agrupados por recurso |
| `requisitos.md` | 13 RF + 7 RNF |
| `uml.md` | ERD + stateDiagram + 2 sequencias + flowchart sessao |
