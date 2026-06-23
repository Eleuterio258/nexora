# API — Modulo Recursos Humanos

## Estrutura Organizacional

A estrutura organizacional e uma arvore hierarquica gerida por closure table.
Cada no pode ter filhos ilimitados. Mover um no reconstroi automaticamente toda a subarvore.

### Nos Organizacionais

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/org | Arvore completa (org chart com caminho e headcount) |
| POST | /api/rh/org | Criar no organizacional (parent_id opcional = raiz) |
| GET | /api/rh/org/{id} | Obter no com caminho, nivel e responsavel |
| PUT | /api/rh/org/{id} | Actualizar dados do no (nome, codigo, responsavel) |
| DELETE | /api/rh/org/{id} | Remover no (so se nao tiver filhos nem funcionarios) |

### Navegacao Hierarquica

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/org/{id}/children | Filhos directos do no |
| GET | /api/rh/org/{id}/subtree | Toda a subarvore (descendentes a qualquer profundidade) |
| GET | /api/rh/org/{id}/path | Caminho da raiz ate ao no (ex: Empresa > TI > Dev) |
| GET | /api/rh/org/{id}/ancestors | Lista de ancestrais ordenada da raiz para o no |
| GET | /api/rh/org/{id}/employees | Funcionarios directos do no |
| GET | /api/rh/org/{id}/employees/all | Funcionarios de todo o no e subarvore |

### Movimentacao

| Metodo | Rota | Descricao |
| --- | --- | --- |
| POST | /api/rh/org/{id}/mover | Mover no para outro pai (valida ciclos, reconstroi subarvore) |

### Cargos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/positions | Listar cargos |
| POST | /api/rh/positions | Criar cargo |
| GET | /api/rh/positions/{id} | Obter cargo |
| PUT | /api/rh/positions/{id} | Actualizar cargo |
| DELETE | /api/rh/positions/{id} | Remover cargo |

### Horarios de Trabalho

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/work-schedules | Listar horarios |
| POST | /api/rh/work-schedules | Criar horario |
| GET | /api/rh/work-schedules/{id} | Obter horario |
| PUT | /api/rh/work-schedules/{id} | Actualizar horario |

---

## Funcionarios

### Gestao de Funcionarios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/employees | Listar funcionarios (filtros: department_id, position_id, estado) |
| POST | /api/rh/employees | Admitir funcionario |
| GET | /api/rh/employees/{id} | Obter ficha completa do funcionario |
| PUT | /api/rh/employees/{id} | Actualizar dados do funcionario |
| POST | /api/rh/employees/{id}/demitir | Registar demissao (motivo, data) |

### Dados Complementares

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/employees/{id}/addresses | Moradas do funcionario |
| POST | /api/rh/employees/{id}/addresses | Adicionar morada |
| PUT | /api/rh/employees/{id}/addresses/{addr_id} | Actualizar morada |
| GET | /api/rh/employees/{id}/emergency-contacts | Contactos de emergencia |
| POST | /api/rh/employees/{id}/emergency-contacts | Adicionar contacto de emergencia |
| PUT | /api/rh/employees/{id}/emergency-contacts/{c_id} | Actualizar contacto |
| GET | /api/rh/employees/{id}/documents | Documentos do funcionario |
| POST | /api/rh/employees/{id}/documents | Adicionar documento |
| DELETE | /api/rh/employees/{id}/documents/{doc_id} | Remover documento |

---

## Contratos e Remuneracao

### Contratos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/employees/{id}/contracts | Historico de contratos |
| POST | /api/rh/employees/{id}/contracts | Criar contrato |
| GET | /api/rh/contracts/{id} | Obter contrato |
| PUT | /api/rh/contracts/{id} | Actualizar contrato |
| POST | /api/rh/contracts/{id}/renovar | Renovar contrato (nova data_fim) |
| POST | /api/rh/contracts/{id}/rescindir | Rescindir contrato |

### Componentes Salariais

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/payroll-components | Listar componentes (subsidios, deducoes, etc.) |
| POST | /api/rh/payroll-components | Criar componente |
| GET | /api/rh/payroll-components/{id} | Obter componente |
| PUT | /api/rh/payroll-components/{id} | Actualizar componente |

### Salarios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/employees/{id}/salaries | Historico salarial |
| POST | /api/rh/employees/{id}/salaries | Registar actualizacao salarial |
| GET | /api/rh/salaries/{id} | Obter registo salarial |

### Beneficios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/employees/{id}/benefits | Beneficios do funcionario |
| POST | /api/rh/employees/{id}/benefits | Adicionar beneficio |
| PUT | /api/rh/employees/{id}/benefits/{b_id} | Actualizar beneficio |
| DELETE | /api/rh/employees/{id}/benefits/{b_id} | Remover beneficio |

---

## Assiduidade

### Presencas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/attendance | Listar registos (filtros: employee_id, data_inicio, data_fim) |
| POST | /api/rh/attendance | Registar presenca |
| GET | /api/rh/attendance/{id} | Obter registo |
| PUT | /api/rh/attendance/{id} | Corrigir registo |
| POST | /api/rh/attendance/{id}/validar | Validar registo de presenca |
| GET | /api/rh/employees/{id}/attendance | Assiduidade do funcionario |

### Horas Extra

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/overtime | Listar horas extra (filtros: employee_id, status) |
| POST | /api/rh/overtime | Solicitar horas extra |
| GET | /api/rh/overtime/{id} | Obter pedido |
| POST | /api/rh/overtime/{id}/aprovar | Aprovar horas extra |
| POST | /api/rh/overtime/{id}/rejeitar | Rejeitar horas extra |

---

## Ferias e Licencas

### Tipos de Licenca

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/leave-types | Listar tipos de licenca |
| POST | /api/rh/leave-types | Criar tipo de licenca |
| PUT | /api/rh/leave-types/{id} | Actualizar tipo |

### Saldos de Licenca

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/employees/{id}/leave-balances | Saldos de licenca do funcionario |
| GET | /api/rh/leave-balances/{id} | Obter saldo especifico |
| POST | /api/rh/leave-balances/ajustar | Ajuste manual de saldo |

### Pedidos de Licenca

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/leaves | Listar pedidos (filtros: employee_id, status, tipo) |
| POST | /api/rh/leaves | Submeter pedido de licenca |
| GET | /api/rh/leaves/{id} | Obter pedido |
| PUT | /api/rh/leaves/{id} | Editar pedido (so em rascunho) |
| POST | /api/rh/leaves/{id}/aprovar | Aprovar pedido |
| POST | /api/rh/leaves/{id}/rejeitar | Rejeitar pedido (motivo obrigatorio) |
| POST | /api/rh/leaves/{id}/cancelar | Cancelar pedido |

---

## Processamento Salarial

### Folhas de Processamento

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/payroll-runs | Listar processamentos (filtros: ano, mes, status) |
| POST | /api/rh/payroll-runs | Criar processamento do mes |
| GET | /api/rh/payroll-runs/{id} | Obter processamento |
| POST | /api/rh/payroll-runs/{id}/processar | Executar calculo do processamento |
| POST | /api/rh/payroll-runs/{id}/aprovar | Aprovar processamento |
| POST | /api/rh/payroll-runs/{id}/pagar | Marcar como pago |
| POST | /api/rh/payroll-runs/{id}/cancelar | Cancelar processamento |

### Recibos de Vencimento

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/payroll-runs/{id}/payslips | Listar recibos do processamento |
| GET | /api/rh/payslips/{id} | Obter recibo detalhado (com linhas) |
| GET | /api/rh/employees/{id}/payslips | Historico de recibos do funcionario |
| GET | /api/rh/payslips/{id}/pdf | Exportar recibo em PDF |

---

## Avaliacao e Desenvolvimento

### Avaliacoes de Desempenho

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/evaluations | Listar avaliacoes (filtros: employee_id, status, periodo) |
| POST | /api/rh/evaluations | Criar avaliacao |
| GET | /api/rh/evaluations/{id} | Obter avaliacao (com criterios) |
| PUT | /api/rh/evaluations/{id} | Actualizar avaliacao |
| POST | /api/rh/evaluations/{id}/submeter | Submeter avaliacao para aprovacao |
| POST | /api/rh/evaluations/{id}/aprovar | Aprovar avaliacao |
| POST | /api/rh/evaluations/{id}/criterios | Adicionar criterio de avaliacao |

### Formacoes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/training | Listar formacoes |
| POST | /api/rh/training | Registar formacao |
| GET | /api/rh/training/{id} | Obter formacao |
| PUT | /api/rh/training/{id} | Actualizar formacao |
| POST | /api/rh/training/{id}/concluir | Marcar como concluida (com certificado) |
| GET | /api/rh/employees/{id}/training | Formacoes do funcionario |

### Processos Disciplinares

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/disciplinary | Listar processos (filtros: employee_id, status, tipo) |
| POST | /api/rh/disciplinary | Abrir processo disciplinar |
| GET | /api/rh/disciplinary/{id} | Obter processo |
| PUT | /api/rh/disciplinary/{id} | Actualizar processo |
| POST | /api/rh/disciplinary/{id}/encerrar | Encerrar processo (sancao aplicada) |
| GET | /api/rh/employees/{id}/disciplinary | Historico disciplinar do funcionario |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/rh/reports/headcount | Quadro de pessoal por departamento |
| GET | /api/rh/reports/payroll-summary | Resumo de processamento salarial (mes/ano) |
| GET | /api/rh/reports/attendance-summary | Resumo de assiduidade por periodo |
| GET | /api/rh/reports/leave-summary | Resumo de ferias e licencas |
| GET | /api/rh/reports/turnover | Taxa de rotatividade (admissoes vs demissoes) |
| GET | /api/rh/reports/salary-mass | Massa salarial por departamento |
| GET | /api/rh/reports/training-hours | Horas de formacao por funcionario/departamento |
