# API — Modulo Contabilidade

## Tipos de Conta

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/account-types | Listar tipos de conta |
| POST | /api/contabilidade/account-types | Criar tipo de conta |
| GET | /api/contabilidade/account-types/{id} | Obter tipo de conta |
| PUT | /api/contabilidade/account-types/{id} | Actualizar |
| DELETE | /api/contabilidade/account-types/{id} | Remover (so sem contas associadas) |

---

## Plano de Contas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/accounts | Listar plano de contas (filtros: account_type_id, aceita_lancamento) |
| POST | /api/contabilidade/accounts | Criar conta |
| GET | /api/contabilidade/accounts/{id} | Obter conta |
| PUT | /api/contabilidade/accounts/{id} | Actualizar conta |
| DELETE | /api/contabilidade/accounts/{id} | Remover (so sem lancamentos) |

---

## Anos e Periodos Fiscais

### Anos Fiscais

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/fiscal-years | Listar anos fiscais |
| POST | /api/contabilidade/fiscal-years | Criar ano fiscal |
| GET | /api/contabilidade/fiscal-years/{id} | Obter ano fiscal com periodos |
| PUT | /api/contabilidade/fiscal-years/{id} | Actualizar ano fiscal |
| POST | /api/contabilidade/fiscal-years/{id}/fechar | Fechar ano fiscal |

### Periodos Fiscais

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/fiscal-periods | Listar periodos (filtros: fiscal_year_id, status) |
| POST | /api/contabilidade/fiscal-periods | Criar periodo fiscal |
| GET | /api/contabilidade/fiscal-periods/{id} | Obter periodo |
| POST | /api/contabilidade/fiscal-periods/{id}/abrir | Reabrir periodo |
| POST | /api/contabilidade/fiscal-periods/{id}/fechar | Iniciar processo de fecho |

---

## Lancamentos Contabilisticos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/journal-entries | Listar lancamentos (filtros: periodo, origem_tipo, data) |
| POST | /api/contabilidade/journal-entries | Criar lancamento (com linhas) |
| GET | /api/contabilidade/journal-entries/{id} | Obter lancamento com linhas |
| PUT | /api/contabilidade/journal-entries/{id} | Corrigir lancamento (so em periodo aberto) |
| DELETE | /api/contabilidade/journal-entries/{id} | Estornar lancamento |
| POST | /api/contabilidade/journal-entries/{id}/lines | Adicionar linha a lancamento |

---

## Impostos

### Grupos de Imposto

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/tax-groups | Listar grupos de imposto |
| POST | /api/contabilidade/tax-groups | Criar grupo |
| PUT | /api/contabilidade/tax-groups/{id} | Actualizar grupo |

### Taxas de Imposto

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/taxes | Listar taxas (filtros: tax_group_id, ativo) |
| POST | /api/contabilidade/taxes | Criar taxa |
| GET | /api/contabilidade/taxes/{id} | Obter taxa com regras |
| PUT | /api/contabilidade/taxes/{id} | Actualizar taxa |
| POST | /api/contabilidade/taxes/{id}/rules | Adicionar regra de calculo |

### Transaccoes de Imposto

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/tax-transactions | Listar (filtros: tax_id, referencia_tipo, periodo) |
| POST | /api/contabilidade/tax-transactions | Registar transaccao de imposto |
| GET | /api/contabilidade/tax-transactions/{id} | Obter transaccao |

---

## Activos Fixos e Amortizacoes

### Activos Fixos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/fixed-assets | Listar activos (filtros: estado, chart_account_id) |
| POST | /api/contabilidade/fixed-assets | Registar activo fixo |
| GET | /api/contabilidade/fixed-assets/{id} | Obter activo com plano de amortizacao |
| PUT | /api/contabilidade/fixed-assets/{id} | Actualizar activo |
| POST | /api/contabilidade/fixed-assets/{id}/alienar | Registar alienacao do activo |
| GET | /api/contabilidade/fixed-assets/{id}/schedule | Plano de amortizacao completo |

### Amortizacoes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/depreciation | Listar amortizacoes (filtros: fixed_asset_id, periodo, status) |
| POST | /api/contabilidade/depreciation/processar | Processar amortizacoes do periodo (cria lancamentos) |
| GET | /api/contabilidade/depreciation/{id} | Obter amortizacao |
| POST | /api/contabilidade/depreciation/{id}/cancelar | Cancelar amortizacao |

---

## Orcamentos Contabilisticos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/budgets | Listar orcamentos (filtros: fiscal_year_id, chart_account_id) |
| POST | /api/contabilidade/budgets | Definir orcamento por conta e ano |
| PUT | /api/contabilidade/budgets/{id} | Actualizar valor orcamentado |
| DELETE | /api/contabilidade/budgets/{id} | Remover orcamento |
| GET | /api/contabilidade/budgets/vs-realizado | Orcado vs. realizado por conta e ano |

---

## Encerramento de Periodo

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/period-closings | Listar encerramentos (filtros: fiscal_period_id, status) |
| POST | /api/contabilidade/period-closings | Iniciar processo de encerramento |
| GET | /api/contabilidade/period-closings/{id} | Obter encerramento com verificacoes |
| POST | /api/contabilidade/period-closings/{id}/verificar | Executar verificacoes automaticas |
| POST | /api/contabilidade/period-closings/{id}/encerrar | Confirmar encerramento (todas verificacoes ok) |
| POST | /api/contabilidade/period-closings/{id}/reabrir | Reabrir periodo encerrado (com justificacao) |

---

## Relatorios Contabilisticos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/contabilidade/reports/trial-balance | Balancete por periodo fiscal |
| GET | /api/contabilidade/reports/balance-sheet | Balanco (activo, passivo, capital) |
| GET | /api/contabilidade/reports/income-statement | Demonstracao de resultados |
| GET | /api/contabilidade/reports/general-ledger | Razao geral por conta e periodo |
| GET | /api/contabilidade/reports/depreciation-summary | Resumo de amortizacoes por periodo |
| GET | /api/contabilidade/reports/budget-execution | Execucao orcamental por conta |
| POST | /api/contabilidade/reports/generate | Gerar e armazenar relatorio (trial_balance, balance_sheet, income_statement) |
