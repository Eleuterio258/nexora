# Requisitos — Modulo Financeiro

## Requisitos Funcionais

### RF01 — Meios de Pagamento

O sistema deve gerir meios de pagamento por tenant (numerario, transferencia, TPA, cheque, MPesa, eMola, credito) com activacao e desactivacao individual.

### RF02 — Registo de Pagamentos e Recebimentos

O sistema deve registar pagamentos (saidas) e recebimentos (entradas) com meio de pagamento, categoria financeira, valor, data e referencia ao documento de origem (fatura, compra, folha salarial).

### RF03 — Distribuicao por Conta ou Caixa

Cada pagamento pode ser distribuido por uma ou mais contas bancarias ou caixas do modulo tesouraria, atraves de linhas de transaccao (`payment_transactions`).

### RF04 — Categorias Financeiras

O sistema deve suportar uma arvore de categorias de receitas e despesas (hierarquia com parent_id) para classificacao de todos os movimentos financeiros.

### RF05 — Contas a Receber

O sistema deve gerir valores em divida por clientes com data de vencimento, valor pendente calculado automaticamente e estados (pendente, parcial, liquidada, vencida, cancelada).

### RF06 — Imputacao de Pagamentos a Receber

O sistema deve permitir imputar um ou varios pagamentos a uma conta a receber, actualizando o valor pago e o estado automaticamente.

### RF07 — Contas a Pagar

O sistema deve gerir valores em divida a fornecedores com os mesmos estados e mecanismo de imputacao das contas a receber.

### RF08 — Imputacao de Pagamentos a Pagar

O sistema deve permitir imputar pagamentos a contas a pagar, actualizando o valor pago e estado.

### RF09 — Alertas de Vencimento

O sistema deve identificar contas a receber e a pagar vencidas (data_vencimento < hoje e status != liquidada) e contas a vencer nos proximos N dias.

### RF10 — Orcamentos Financeiros

O sistema deve permitir definir orcamentos por categoria financeira, ano e mes, para comparacao com valores realizados.

### RF11 — Execucao Orcamental

O sistema deve calcular a execucao orcamental (orcado vs. realizado) por categoria e periodo.

### RF12 — Fluxo de Caixa

O sistema deve registar entradas e saidas de caixa realizadas e previstas, permitindo projecao de saldo futuro por categoria.

### RF13 — Relatorios Financeiros

O sistema deve gerar e armazenar os seguintes relatorios:

- Demonstracao de Resultados (DRE) por periodo
- Resumo de fluxo de caixa
- Antiguidade de saldos a receber (aging receivables)
- Antiguidade de saldos a pagar (aging payables)
- Execucao orcamental por categoria

---

## Requisitos Nao Funcionais

### RNF01 — Atomicidade

O registo de um pagamento, a imputacao a conta a receber/pagar e a actualizacao do saldo na tesouraria devem ocorrer na mesma transaccao de base de dados.

### RNF02 — Valor Pendente Calculado

O campo `valor_pendente` em `accounts_receivable` e `accounts_payable` deve ser coluna computed (`GENERATED ALWAYS AS STORED`) para garantir consistencia sem logica de aplicacao.

### RNF03 — Rastreabilidade de Origem

Cada pagamento e cada conta a receber/pagar deve referenciar o documento de origem via `referencia_tipo` (invoice, purchase_order, payroll_run) e `referencia_id`.

### RNF04 — Imutabilidade de Pagamentos Confirmados

Um pagamento confirmado nao pode ser editado. Apenas pode ser cancelado com registo de motivo, gerando novo pagamento de estorno se necessario.

### RNF05 — Auditoria

Registo, confirmacao e cancelamento de pagamentos, bem como liquidacao de contas a receber e a pagar, devem gerar registos no modulo de auditoria.

### RNF06 — Desempenho

Consulta de pagamentos por periodo e tenant: menos de 500ms. Listagem de contas vencidas: menos de 300ms (indice em data_vencimento).

### RNF07 — Consistencia de Orcamento

Nao pode existir mais de um orcamento para a mesma combinacao tenant + categoria + ano + mes (constraint UNIQUE).
