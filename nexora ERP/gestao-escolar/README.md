# Modulo de Gestao Escolar

Sistema de gestao escolar para colegios e escolas com foco em administracao academica, cargos escolares, propinas, comunicacao e acompanhamento de desempenho.

## Estrutura

O `gestao-escolar` e um modulo de negocio que consome `autenticacao`, `autorizacao` e `utilizadores`. O modulo pode ser organizado internamente em submodulos funcionais para separar responsabilidades sem criar duplicacao de login ou permissoes.

## Submodulos

| Submodulo | Responsabilidade |
| --- | --- |
| `administracao-escolar` | Anos lectivos, periodos, turmas, salas, horarios e calendario escolar |
| `gestao-alunos` | Cadastro de alunos, encarregados, matriculas, rematriculas, transferencias e historico |
| `gestao-professores` | Cadastro de professores, atribuicoes por turma/disciplina e carga lectiva |
| `academico` | Disciplinas, frequencia, avaliacoes, notas, medias e boletins |
| `cargos-escolares` | Cargos de alunos e professores por turma, ciclo ou escola |
| `financeiro-escolar` | Propinas, matriculas, taxas, descontos, bolsas, entidade, referencia e recibos |
| `biblioteca` | Catalogo de livros, emprestimos, devolucoes e controlo de atrasos |
| `comunicacao-escolar` | Mensagens, circulares, alertas e notificacoes para alunos, encarregados e professores |
| `relatorios-escolares` | Indicadores academicos, financeiros e dashboard da direccao |
| `portal-aluno` | Consulta de notas, frequencia, pagamentos e comunicados |
| `portal-professor` | Diario de turma, lancamento de notas, frequencia e materiais |
| `portal-encarregado` | Acompanhamento academico e financeiro do educando |

## Documentacao detalhada

- submodulos/README.md - indice dos submodulos documentados

## Dependencias

- `autenticacao` - login de alunos, encarregados, professores e administracao
- `autorizacao` - perfis e permissoes por portal (`aluno`, `encarregado`, `professor`, `direccao`, `financeiro`)
- `utilizadores` - ligacao entre entidades humanas e contas do sistema
- `auditoria` - trilha de alteracoes em notas, frequencias, matriculas e pagamentos
- `financeiro` - contas a receber, recebimentos e reconciliacao de propinas
- `tesouraria` - destino de recebimentos em caixa, banco, M-Pesa e e-Mola

## Tabelas

| Tabela | Descricao |
| --- | --- |
| `school_years` | Anos lectivos por tenant com datas e estado |
| `school_terms` | Periodos lectivos (trimestre/semestre) usados em notas e cobrancas |
| `classes` | Turmas com serie, turno, sala e professor director |
| `subjects` | Disciplinas com carga horaria e area academica |
| `teachers` | Cadastro de professores |
| `teacher_assignments` | Vinculo de professor a turma/disciplina no ano lectivo |
| `teacher_roles` | Cargos escolares de professores (`director_turma`, `director_ciclo`, etc.) |
| `students` | Cadastro de alunos |
| `student_guardians` | Responsaveis financeiros e contactos do aluno |
| `enrollments` | Matriculas e rematriculas por ano lectivo |
| `student_roles` | Cargos dos alunos por turma (`chefe_turma`, `adjunto`, etc.) |
| `attendance_records` | Frequencia por aula, aluno e disciplina |
| `grade_items` | Avaliacoes planejadas por turma/disciplina/periodo |
| `grades` | Lancamento de notas por aluno |
| `fee_plans` | Plano de cobrancas escolares (matricula, propina, exame, transporte) |
| `student_invoices` | Titulos financeiros do aluno com entidade e referencia |
| `student_payments` | Pagamentos e conciliacao com referencia unica |
| `library_books` | Catalogo de livros da biblioteca |
| `library_loans` | Emprestimos e devolucoes de livros |
| `school_messages` | Comunicacoes para aluno, encarregado, turma ou escola |

## Ficheiros

| Ficheiro | Descricao |
| --- | --- |
| `database-gestao-escolar.sql` | Schema PostgreSQL com tabelas, constraints e indices |
| `api-gestao-escolar.md` | Endpoints REST para academico, financeiro e comunicacao |
| `requisitos.md` | Requisitos funcionais e nao funcionais |
| `uml.md` | Diagramas ERD, fluxos de matricula, cobranca e lancamento de notas |

