# Modulo de Recursos Humanos

Gestao completa do ciclo de vida do colaborador: admissao, contratos, processamento salarial, assiduidade, licencas, avaliacao de desempenho e desenvolvimento.

## Dependencias

- `financeiro` — integracao para pagamento de salarios e subsidios
- `contabilidade` — lancamentos contabilisticos do processamento salarial
- `autenticacao` — user_id para responsavel, aprovadores e auditoria

## Tabelas

### Estrutura Organizacional

| Tabela | Descricao |
| --- | --- |
| `org_units` | Nos da estrutura organizacional (parent_id, nivel) — nome livre por empresa |
| `org_closures` | Closure table — todos os pares ancestral/descendente com profundidade |
| `employee_positions` | Cargos com grau salarial e intervalo de salario |
| `work_schedules` | Horarios de trabalho (horas diarias, dias por semana) |

### Gestao de Funcionarios

| Tabela | Descricao |
| --- | --- |
| `employees` | Ficha completa do funcionario (dados pessoais, fiscais, estado) |
| `employee_addresses` | Moradas do funcionario |
| `employee_emergency_contacts` | Contactos de emergencia |
| `employee_documents` | Documentos (BI, passaporte, carta de conducao, etc.) |

### Contratos e Remuneracao

| Tabela | Descricao |
| --- | --- |
| `employee_contracts` | Contratos de trabalho (tipo, regime, datas, status) |
| `payroll_components` | Componentes salariais configurados (subsidios, deducoes, bonus) |
| `employee_salaries` | Historico de actualizacoes salariais |
| `employee_benefits` | Beneficios por funcionario (seguro, viatura, etc.) |

### Assiduidade

| Tabela | Descricao |
| --- | --- |
| `employee_attendance` | Registos diarios de presenca (entrada, saida, horas extra) |
| `employee_overtime` | Pedidos e aprovacao de horas extraordinarias |

### Ferias e Licencas

| Tabela | Descricao |
| --- | --- |
| `employee_leave_types` | Tipos de licenca (ferias, baixa, maternidade, etc.) |
| `employee_leave_balances` | Saldo de dias por funcionario, tipo e ano |
| `employee_leaves` | Pedidos de licenca com fluxo de aprovacao |

### Processamento Salarial

| Tabela | Descricao |
| --- | --- |
| `payroll_runs` | Cabecalho do processamento mensal (totais, status, aprovacao) |
| `employee_payroll` | Recibo de vencimento por funcionario e processamento |
| `employee_payroll_items` | Linhas detalhadas do recibo (componente a componente) |

### Avaliacao e Desenvolvimento

| Tabela | Descricao |
| --- | --- |
| `employee_evaluations` | Avaliacoes de desempenho (pontuacao, classificacao, plano) |
| `evaluation_criteria` | Criterios individuais de cada avaliacao |
| `employee_training` | Formacoes realizadas (custo, horas, certificado) |
| `employee_disciplinary` | Processos disciplinares (tipo, sancao, status) |

## Views

| View | Ficheiro | Descricao |
| --- | --- | --- |
| `vw_rh_employees` | views-rh.sql | Ficha resumida com departamento e cargo actuais |
| `vw_rh_salario_actual` | views-rh.sql | Salario base actual de cada funcionario |
| `vw_rh_payslips` | views-rh.sql | Recibos com dados do processamento e funcionario |
| `vw_rh_leave_balances` | views-rh.sql | Saldos de licenca com dias disponiveis calculados |
| `vw_rh_leaves` | views-rh.sql | Pedidos de licenca com nome do aprovador |
| `vw_rh_attendance_mensal` | views-rh.sql | Totais mensais de assiduidade e horas extra |
| `vw_rh_headcount` | views-rh.sql | Quadro de pessoal activo por departamento (simples) |
| `vw_rh_massa_salarial` | views-rh.sql | Massa salarial bruta e salario medio por departamento |
| `vw_rh_org_chart` | hierarchy-rh.sql | Org chart completo com caminho de nomes e headcount acumulado |
| `vw_rh_headcount_hierarquico` | hierarchy-rh.sql | Directos vs. total da subarvore por departamento |
| `vw_rh_employee_org_path` | hierarchy-rh.sql | Caminho organizacional completo de cada funcionario |

## Funcoes (hierarquia)

| Funcao | Descricao |
| --- | --- |
| `fn_org_mover(dept_id, novo_pai_id)` | Move departamento validando que o destino nao e subarvore propria |
| `fn_org_subarvore(dept_id)` | Devolve todos os descendentes com profundidade |
| `fn_org_caminho(dept_id)` | Devolve o caminho da raiz ate ao departamento |

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database-rh.sql` | Schema completo com todas as tabelas, constraints e indices |
| `hierarchy-rh.sql` | Closure table, triggers, funcoes e views de hierarquia |
| `views-rh.sql` | Views de consulta e relatorios operacionais |
| `api-rh.md` | Endpoints REST agrupados por recurso |
| `requisitos.md` | Requisitos funcionais e nao funcionais |
| `uml.md` | Diagramas ERD, fluxos e sequencias |

## Ordem de execucao

```text
1. database-rh.sql   — tabelas base
2. hierarchy-rh.sql  — closure table, triggers, funcoes de hierarquia
3. views-rh.sql      — views operacionais
```
