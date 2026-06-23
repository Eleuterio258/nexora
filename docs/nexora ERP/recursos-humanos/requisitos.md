# Requisitos — Modulo Recursos Humanos

## Requisitos Funcionais

### RF01 — Registo de Colaboradores
O sistema deve permitir criar colaboradores com numero unico, nome, NUIT, INSS, data de admissao e estado.

### RF02 — Departamentos e Cargos
O sistema deve gerir departamentos e cargos, permitindo associar cada colaborador a um departamento e cargo.

### RF03 — Contratos de Trabalho
O sistema deve registar contratos de trabalho por colaborador com tipo, data de inicio, data de fim e salario.

### RF04 — Salarios
O sistema deve manter o historico de salarios base por colaborador com vigencia temporal e moeda.

### RF05 — Registo de Assiduidade
O sistema deve registar a assiduidade diaria dos colaboradores com hora de entrada, hora de saida e estado.

### RF06 — Gestao de Ferias e Ausencias
O sistema deve gerir pedidos de ferias e ausencias por tipo, com estados: pendente, aprovada, gozada e cancelada.

### RF07 — Tipos de Ausencia
O sistema deve suportar a configuracao de tipos de ausencia por tenant (ferias, doenca, formacao, justificada, injustificada).

### RF08 — Processamento de Salarios
O sistema deve processar folhas de salario por colaborador com totais de proventos, descontos e liquido a receber.

### RF09 — Itens de Salario
O sistema deve detalhar cada folha de salario em itens do tipo provento ou desconto com descricao e valor.

### RF10 — Documentos do Colaborador
O sistema deve permitir anexar documentos ao colaborador (BI, contrato, certificados) com numero e datas.

### RF11 — Avaliacoes de Desempenho
O sistema deve registar avaliacoes periodicas de desempenho por colaborador com pontuacao e comentario.

---

## Requisitos Nao Funcionais

### RNF01 — Numero Unico de Colaborador
O numero do colaborador deve ser unico por tenant.

### RNF02 — Confidencialidade Salarial
Os dados salariais dos colaboradores devem ser acessiveis apenas a utilizadores com permissao especifica (RH, Financeiro).

### RNF03 — Integracao com Contabilidade
O processamento de uma folha de salario deve gerar automaticamente um lancamento contabilistico no modulo de contabilidade.

### RNF04 — Integridade de Contratos
Nao deve ser possivel processar salario para um colaborador sem contrato activo.

### RNF05 — Auditoria
Admissao, demissao, alteracoes salariais e processamento de folhas devem gerar registos no modulo de auditoria.

### RNF06 — Desempenho
O processamento da folha de salario para ate 500 colaboradores deve concluir em menos de 30 segundos.
