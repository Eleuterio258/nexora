# Modulo de Contabilidade

Contabilidade de dupla entrada com plano de contas, lancamentos contabilisticos, impostos, activos fixos, orcamentos e encerramento de periodo.

## Dependencias

- `modulo-faturacao` — origina lancamentos via origem_tipo=invoice
- `compras` — origina lancamentos via origem_tipo=purchase_order
- `financeiro` — origina lancamentos via origem_tipo=payment
- `recursos-humanos` — origina lancamentos via origem_tipo=payroll_run
- `pos` — origina lancamentos via origem_tipo=pos_sale
- `centros-custo` — consome fiscal_period_id e journal_entry_line_id

## Tabelas

### Plano de Contas e Periodos

| Tabela | Descricao |
| --- | --- |
| `account_types` | Tipos de conta com natureza debito ou credito |
| `chart_of_accounts` | Plano de contas por tenant com tipo e flag aceita_lancamento |
| `fiscal_years` | Anos fiscais com data de inicio, fim e estado |
| `fiscal_periods` | Periodos fiscais (mensais/trimestrais) dentro do ano fiscal |

### Lancamentos

| Tabela | Descricao |
| --- | --- |
| `journal_entries` | Cabecalho do lancamento com numero, data, periodo e documento de origem |
| `journal_entry_lines` | Linhas do lancamento (conta, debito, credito) |

### Impostos

| Tabela | Descricao |
| --- | --- |
| `tax_groups` | Grupos de imposto (IVA, IRPS, etc.) |
| `taxes` | Taxas com percentagem e estado activo/inactivo |
| `tax_rules` | Regras de calculo por taxa |
| `tax_transactions` | Transaccoes de imposto com base imponivel e valor calculado |

### Relatorios Gerados

| Tabela | Descricao |
| --- | --- |
| `trial_balance` | Balancetes gerados por periodo (dados em JSONB) |
| `balance_sheet` | Balancos gerados por periodo (dados em JSONB) |
| `income_statement` | Demonstracoes de resultados geradas (dados em JSONB) |

### Activos Fixos e Amortizacoes

| Tabela | Descricao |
| --- | --- |
| `fixed_assets` | Activos fixos com metodo de amortizacao e estado |
| `depreciation_schedules` | Plano de amortizacao por activo e periodo com lancamento associado |

### Orcamentos e Encerramento

| Tabela | Descricao |
| --- | --- |
| `budget_accounts` | Orcamento contabilistico por conta e ano fiscal |
| `period_closings` | Processo de encerramento de periodo com estado e aprovador |
| `closing_checks` | Verificacoes individuais do encerramento (balancete, amortizacoes, impostos) |

## Views

| View | Descricao |
| --- | --- |
| `vw_balancete` | Debito, credito e saldo acumulado por conta |
| `vw_balancete_periodo` | Balancete filtrado por periodo fiscal |
| `vw_demonstracao_resultados` | Receitas vs. despesas por periodo |
| `vw_razao_geral` | Todos os lancamentos por conta ordenados por data |
| `vw_fixed_assets_estado` | Activos com valor contabilistico actual (lateral join) |
| `vw_plano_amortizacao` | Plano de amortizacao por activo e periodo |
| `vw_budget_vs_realizado` | Orcado vs. realizado com desvio por conta e ano |
| `vw_period_closing_checks` | Verificacoes de encerramento com estado por periodo |

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database-contabilidade.sql` | Schema completo — 18 tabelas, constraints, indices |
| `views-contabilidade.sql` | 8 views de consulta e relatorios |
| `api-contabilidade.md` | Endpoints REST agrupados por recurso |
| `requisitos.md` | 18 RF + 7 RNF |
| `uml.md` | ERD completo + 5 diagramas |
