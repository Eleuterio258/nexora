# API — Modulo Financeiro

## Meios de Pagamento

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/payment-methods | Listar meios de pagamento |
| POST | /api/financeiro/payment-methods | Criar meio de pagamento |
| GET | /api/financeiro/payment-methods/{id} | Obter meio de pagamento |
| PUT | /api/financeiro/payment-methods/{id} | Actualizar |
| DELETE | /api/financeiro/payment-methods/{id} | Desactivar |

---

## Categorias Financeiras

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/categories | Arvore de categorias (receitas e despesas) |
| POST | /api/financeiro/categories | Criar categoria |
| GET | /api/financeiro/categories/{id} | Obter categoria |
| PUT | /api/financeiro/categories/{id} | Actualizar categoria |
| DELETE | /api/financeiro/categories/{id} | Remover (so sem movimentos) |

---

## Pagamentos e Recebimentos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/payments | Listar (filtros: tipo, status, data_inicio, data_fim) |
| POST | /api/financeiro/payments | Registar pagamento ou recebimento |
| GET | /api/financeiro/payments/{id} | Obter pagamento com transacoes |
| PUT | /api/financeiro/payments/{id} | Actualizar (so em pendente) |
| POST | /api/financeiro/payments/{id}/confirmar | Confirmar pagamento |
| POST | /api/financeiro/payments/{id}/cancelar | Cancelar pagamento |

---

## Contas a Receber

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/receivables | Listar (filtros: status, customer_id, vencimento) |
| POST | /api/financeiro/receivables | Criar conta a receber |
| GET | /api/financeiro/receivables/{id} | Obter conta com pagamentos imputados |
| PUT | /api/financeiro/receivables/{id} | Actualizar conta |
| POST | /api/financeiro/receivables/{id}/imputar | Imputar pagamento a esta conta |
| POST | /api/financeiro/receivables/{id}/cancelar | Cancelar conta a receber |
| GET | /api/financeiro/receivables/vencidas | Contas vencidas (data_vencimento < hoje) |
| GET | /api/financeiro/receivables/a-vencer | Contas a vencer nos proximos N dias |

---

## Contas a Pagar

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/payables | Listar (filtros: status, supplier_id, vencimento) |
| POST | /api/financeiro/payables | Criar conta a pagar |
| GET | /api/financeiro/payables/{id} | Obter conta com pagamentos imputados |
| PUT | /api/financeiro/payables/{id} | Actualizar conta |
| POST | /api/financeiro/payables/{id}/imputar | Imputar pagamento a esta conta |
| POST | /api/financeiro/payables/{id}/cancelar | Cancelar conta a pagar |
| GET | /api/financeiro/payables/vencidas | Contas vencidas (data_vencimento < hoje) |
| GET | /api/financeiro/payables/a-vencer | Contas a vencer nos proximos N dias |

---

## Orcamentos Financeiros

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/budgets | Listar orcamentos (filtros: ano, mes) |
| POST | /api/financeiro/budgets | Definir orcamento por categoria e periodo |
| PUT | /api/financeiro/budgets/{id} | Actualizar valor orcamentado |
| DELETE | /api/financeiro/budgets/{id} | Remover orcamento |
| GET | /api/financeiro/budgets/vs-realizado | Orcado vs. realizado por categoria e periodo |

---

## Fluxo de Caixa

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/cash-flow | Fluxo de caixa por periodo (realizado + previsto) |
| POST | /api/financeiro/cash-flow | Registar entrada ou saida prevista |
| GET | /api/financeiro/cash-flow/{id} | Obter lancamento |
| DELETE | /api/financeiro/cash-flow/{id} | Remover lancamento previsto |
| GET | /api/financeiro/cash-flow/projecao | Projecao de saldo futuro por categoria |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/financeiro/reports/dre | Demonstracao de Resultados por periodo |
| GET | /api/financeiro/reports/cash-flow-summary | Resumo do fluxo de caixa |
| GET | /api/financeiro/reports/aging-receivables | Antiguidade de saldos a receber |
| GET | /api/financeiro/reports/aging-payables | Antiguidade de saldos a pagar |
| GET | /api/financeiro/reports/budget-execution | Execucao orcamental por categoria |
