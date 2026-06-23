# Requisitos — Modulo Gestao de Clientes

## Requisitos Funcionais

### RF01 — Registo de Cliente
O sistema deve permitir criar clientes com codigo, nome, NUIT, telefone, email e estado, associados a um tenant.

### RF02 — Grupos de Clientes
O sistema deve suportar a classificacao de clientes em grupos, permitindo aplicar regras e descontos por grupo.

### RF03 — Multiplos Contactos
O sistema deve permitir registar varios contactos por cliente, com cargo e indicacao do contacto principal.

### RF04 — Multiplas Moradas
O sistema deve suportar multiplas moradas por cliente: principal, entrega, cobranca e fiscal.

### RF05 — Documentos do Cliente
O sistema deve permitir anexar documentos ao cliente (NUIT, BI, contratos) com numero, URL e datas de validade.

### RF06 — Limite de Credito
O sistema deve permitir definir um limite de credito por cliente com moeda, vigencia e estado activo/inactivo.

### RF07 — Saldo do Cliente
O sistema deve manter o saldo actual, saldo vencido e credito disponivel de cada cliente actualizados em tempo real.

### RF08 — Historico de Pagamentos
O sistema deve registar os pagamentos recebidos de clientes com metodo, referencia, valor e data.

### RF09 — Notas Internas
O sistema deve permitir adicionar notas internas a um cliente, identificando o autor.

### RF10 — Historico de Eventos
O sistema deve manter um historico de eventos do cliente (criacao, alteracao, vendas, pagamentos) com referencia ao documento origem.

### RF11 — Tags de Cliente
O sistema deve suportar a criacao de tags e a sua atribuicao a clientes para categorizacao flexivel.

### RF12 — Descontos por Cliente
O sistema deve permitir configurar descontos individuais por cliente (percentual ou valor fixo) com vigencia temporal.

### RF13 — Bloqueio de Cliente
O sistema deve permitir bloquear um cliente, impedindo a emissao de novos documentos para esse cliente.

---

## Requisitos Nao Funcionais

### RNF01 — Unicidade de NUIT
O NUIT do cliente deve ser unico por tenant. Deve ser validado no formato moçambicano.

### RNF02 — Codigo Unico
O codigo do cliente deve ser unico por tenant. O sistema deve suportar geracao automatica de codigo sequencial.

### RNF03 — Saldo em Tempo Real
O saldo do cliente deve ser actualizado de forma atomica a cada transaccao, sem inconsistencias.

### RNF04 — Desempenho de Pesquisa
A pesquisa de clientes por nome, codigo ou NUIT deve responder em menos de 300ms para datasets de ate 100.000 clientes.

### RNF05 — Auditoria
Criacao, alteracao de estado e alteracao de limite de credito devem gerar registos de auditoria.
