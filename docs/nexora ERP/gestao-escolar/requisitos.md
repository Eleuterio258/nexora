# Requisitos — Modulo Gestao Escolar

## Requisitos Funcionais

### RF01 — Cadastro Escolar

O sistema deve permitir cadastrar alunos, encarregados, professores e funcionarios com dados pessoais, contactos, documentos e estado activo/inactivo.

### RF02 — Anos Lectivos e Periodos

O sistema deve gerir anos lectivos e periodos (trimestres ou semestres), impedindo sobreposicao de datas para o mesmo tenant.

### RF03 — Turmas e Horarios

O sistema deve permitir criar turmas por serie, ciclo, turno, sala e capacidade, associando professores directores e horarios.

### RF04 — Matricula e Rematricula

O sistema deve suportar matricula, rematricula, transferencia interna e saida do aluno, mantendo historico por ano lectivo.

### RF05 — Referencia de Matricula

Cada matricula deve gerar uma referencia unica legivel, por exemplo `ALU2026-0001`, usada como identificador funcional do aluno.

### RF06 — Cargos de Alunos

O sistema deve permitir atribuir a um aluno, por turma e periodo de vigencia, um cargo escolar como `chefe_turma`, `adjunto`, `higiene`, `seguranca`, `chefe_grupo` ou `informacao`.

### RF07 — Cargos de Professores

O sistema deve permitir atribuir a um professor um ou varios cargos como `director_turma`, `director_ciclo`, `director_disciplina` ou `director_escola`, com possibilidade de vinculo a turma ou nivel institucional.

### RF08 — Plano Curricular

O sistema deve gerir disciplinas, carga horaria e atribuicoes de professores por turma, disciplina e ano lectivo.

### RF09 — Frequencia

O sistema deve permitir lancar presencas, faltas justificadas e faltas injustificadas por aula, aluno e disciplina.

### RF10 — Notas e Boletim

O sistema deve suportar criacao de itens de avaliacao, lancamento de notas, calculo de media por periodo e emissao de boletim.

### RF11 — Portal do Professor

O portal do professor deve permitir consultar turmas, horarios, diarios, lancar notas, frequencias e materiais de apoio.

### RF12 — Portal do Aluno e Encarregado

O portal do aluno/encarregado deve mostrar notas, frequencia, comunicacoes, propinas em aberto, historico de pagamentos e recibos.

### RF13 — Plano de Propinas e Taxas

O sistema deve permitir configurar valores por ano, classe, curso e tipo de taxa (`matricula`, `propina`, `exame`, `uniforme`, `transporte`, `multa`).

### RF14 — Entidade e Referencia de Pagamento

Cada cobranca ao aluno deve gerar `entidade`, `referencia_pagamento` e `codigo_documento` unicos, suportando rastreio e conciliacao automatica.

### RF15 — Integracao com Pagamentos Nacionais

O sistema deve registar pagamentos vindos de caixa, transferencia bancaria, M-Pesa, e-Mola e gateways bancarios, com suporte a callback/webhook para confirmacao automatica.

### RF16 — Recibos Digitais

Apos confirmacao do pagamento, o sistema deve gerar recibo digital e actualizar o estado da cobranca para `parcial`, `paga` ou `vencida`.

### RF17 — Biblioteca

O sistema deve gerir cadastro de livros, emprestimos, devolucoes e alertas de atraso por aluno ou professor.

### RF18 — Comunicacao Escolar

O sistema deve permitir envio de mensagens e circulares por aluno, turma, encarregado ou publico geral da escola.

### RF19 — Relatorios Academicos

O sistema deve gerar relatorios por turma, disciplina, aluno, professor e periodo, incluindo ranking, aproveitamento e absentismo.

### RF20 — Relatorios Financeiros

O sistema deve gerar relatorios de propinas pagas, pendentes, inadimplencia, descontos, bolsas e cobrancas por periodo.

### RF21 — Dashboard da Direccao

O sistema deve apresentar indicadores de matriculas, ocupacao por turma, aprovacao, reprovacao, recebimentos e inadimplencia.

---

## Requisitos Nao Funcionais

### RNF01 — Segregacao por Perfil

Cada perfil deve aceder apenas aos dados necessarios ao seu papel, impedindo que um aluno veja dados de outros alunos ou que um professor veja turmas nao atribuídas.

### RNF02 — Rastreabilidade

Notas, frequencias, cargos, matriculas e pagamentos devem manter historico de criacao, alteracao e anulacao com utilizador e timestamp.

### RNF03 — Integridade Academica

O sistema nao deve permitir lancamento de nota ou frequencia para aluno sem matricula activa na turma e periodo correspondente.

### RNF04 — Integridade Financeira

A actualizacao de pagamento, recibo e conta a receber deve ocorrer na mesma transaccao de base de dados.

### RNF05 — Referencias Unicas

Referencias de matricula, cobranca e pagamento devem ser unicas por tenant e resistentes a duplicacao em ambiente concorrente.

### RNF06 — Desempenho

O carregamento do boletim de um aluno e do extracto financeiro do encarregado deve concluir em menos de 2 segundos com ate 10 mil alunos por tenant.

### RNF07 — Conformidade e Privacidade

Os dados pessoais e academicos devem respeitar politicas de privacidade, retencao e controlo de acesso com encriptacao de segredos de integracao.
