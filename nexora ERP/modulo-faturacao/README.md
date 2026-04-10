# Modulo de Faturacao

Ciclo completo de vendas: orcamentos, encomendas, guias de remessa, faturas, recibos, notas de credito e devolucoes.

## Dependencias

- `gestao-clientes` — `customer_id` em todos os documentos
- `gestao-produtos` — `product_id` nas linhas de documento
- `gestao-stock` — verifica disponibilidade e regista saidas/entradas
- `financeiro` — cria `accounts_receivable` ao emitir fatura; recebe imputacao de recibos
- `contabilidade` — recebe `journal_entries` via `origem_tipo=invoice`

## Tabelas

### Numeracao

| Tabela | Descricao |
| --- | --- |
| `invoice_series` | Series documentais por tipo (ORC, ENC, GR, FT, NC, RB) e ano com sequencia atomica |

### Orcamentos

| Tabela | Descricao |
| --- | --- |
| `sales_quotes` | Orcamentos com validade, totais calculados e estados |
| `sales_quote_items` | Linhas com desconto por linha e imposto por linha |

### Encomendas

| Tabela | Descricao |
| --- | --- |
| `sales_orders` | Encomendas com rastreio de entrega por linha |
| `sales_order_items` | Linhas com quantidade encomendada e quantidade entregue |

### Guias de Remessa

| Tabela | Descricao |
| --- | --- |
| `sales_deliveries` | Guias de remessa com estado de transporte e entrega |
| `sales_delivery_items` | Linhas de entrega ligadas aos itens da encomenda |

### Faturas

| Tabela | Descricao |
| --- | --- |
| `invoices` | Faturas com saldo pendente calculado (GENERATED ALWAYS AS STORED) |
| `invoice_items` | Linhas com desconto e imposto por linha |
| `invoice_taxes` | Resumo de impostos por fatura (base imponivel e valor) |
| `invoice_discounts` | Descontos ao nivel do documento (percentual ou valor fixo) |

### Recibos

| Tabela | Descricao |
| --- | --- |
| `invoice_receipts` | Recibos numerados com meio de pagamento |

### Notas de Credito

| Tabela | Descricao |
| --- | --- |
| `credit_notes` | Documento fiscal de anulacao parcial ou total de fatura |
| `credit_note_items` | Linhas da nota de credito |

### Devolucoes

| Tabela | Descricao |
| --- | --- |
| `sales_returns` | Devolucoes fisicas com estado de recepcao |
| `sales_return_items` | Itens devolvidos com estado do produto (bom, danificado, defeito) |

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database.sql` | Schema completo — 16 tabelas, constraints, indices |
| `api-faturacao.md` | Endpoints REST agrupados por documento |
| `requisitos.md` | 17 RF + 7 RNF |
| `uml.md` | ERD + stateDiagram + 3 sequencias + flowchart ciclo de venda |
