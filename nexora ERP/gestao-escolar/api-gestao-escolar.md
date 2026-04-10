# API - Modulo Gestao Escolar

## Organizacao por Submodulos

- `administracao-escolar` - anos lectivos, periodos, turmas e atribuicoes base
- `gestao-alunos` - alunos, encarregados e matriculas
- `cargos-escolares` - cargos de alunos e professores
- `academico` - frequencia, avaliacoes, notas e boletins
- `financeiro-escolar` - planos de cobranca, propinas, pagamentos e recibos
- `biblioteca` - livros e emprestimos
- `comunicacao-escolar` - mensagens, circulares, dashboard e relatorios

## Anos Lectivos e Periodos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/years | Listar anos lectivos |
| POST | /api/escolar/years | Criar ano lectivo |
| GET | /api/escolar/years/{id} | Obter ano lectivo |
| PUT | /api/escolar/years/{id} | Actualizar ano lectivo |
| POST | /api/escolar/years/{id}/activar | Activar ano lectivo |
| POST | /api/escolar/years/{id}/close | Encerrar ano lectivo |
| POST | /api/escolar/years/{id}/terms | Criar periodo lectivo |

---

## Turmas e Disciplinas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/classes | Listar turmas |
| POST | /api/escolar/classes | Criar turma |
| GET | /api/escolar/classes/{id} | Obter turma com alunos e horarios |
| PUT | /api/escolar/classes/{id} | Actualizar turma |
| POST | /api/escolar/classes/{id}/assign-teacher | Associar professor director |
| GET | /api/escolar/subjects | Listar disciplinas |
| POST | /api/escolar/subjects | Criar disciplina |
| POST | /api/escolar/teacher-assignments | Atribuir professor a turma/disciplina |

---

## Alunos e Matriculas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/students | Listar alunos |
| POST | /api/escolar/students | Cadastrar aluno |
| GET | /api/escolar/students/{id} | Obter aluno com encarregados |
| PUT | /api/escolar/students/{id} | Actualizar cadastro do aluno |
| POST | /api/escolar/students/{id}/guardians | Adicionar encarregado |
| POST | /api/escolar/enrollments | Efectuar matricula/rematricula |
| GET | /api/escolar/enrollments/{id} | Obter matricula |
| POST | /api/escolar/enrollments/{id}/transfer | Transferir aluno |
| POST | /api/escolar/enrollments/{id}/cancel | Cancelar matricula |

---

## Cargos Escolares

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/student-roles | Listar cargos de alunos |
| POST | /api/escolar/student-roles | Atribuir cargo ao aluno |
| PUT | /api/escolar/student-roles/{id} | Actualizar vigencia do cargo |
| POST | /api/escolar/student-roles/{id}/revoke | Revogar cargo do aluno |
| GET | /api/escolar/teacher-roles | Listar cargos de professores |
| POST | /api/escolar/teacher-roles | Atribuir cargo ao professor |
| PUT | /api/escolar/teacher-roles/{id} | Actualizar cargo do professor |
| POST | /api/escolar/teacher-roles/{id}/revoke | Revogar cargo do professor |

---

## Frequencia e Notas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/attendance | Listar frequencias (filtros: turma, disciplina, data) |
| POST | /api/escolar/attendance | Lancar frequencia |
| PUT | /api/escolar/attendance/{id} | Corrigir registo de frequencia |
| GET | /api/escolar/grade-items | Listar avaliacoes |
| POST | /api/escolar/grade-items | Criar avaliacao |
| POST | /api/escolar/grades | Lancar notas |
| PUT | /api/escolar/grades/{id} | Corrigir nota |
| GET | /api/escolar/report-cards/{student_id} | Obter boletim por periodo |

---

## Financeiro Escolar

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/fee-plans | Listar planos de propinas e taxas |
| POST | /api/escolar/fee-plans | Criar plano de cobranca |
| POST | /api/escolar/student-invoices | Gerar cobranca para aluno |
| GET | /api/escolar/student-invoices | Listar cobrancas (filtros: aluno, status, vencimento) |
| GET | /api/escolar/student-invoices/{id} | Obter cobranca com entidade e referencia |
| POST | /api/escolar/student-invoices/{id}/emit | Emitir cobranca |
| POST | /api/escolar/student-invoices/{id}/discount | Aplicar desconto ou bolsa |
| POST | /api/escolar/payments | Registar pagamento manual |
| POST | /api/escolar/payments/callback | Receber callback de gateway/banco |
| GET | /api/escolar/payments/{id} | Obter pagamento e conciliacao |
| GET | /api/escolar/payments/{id}/receipt | Gerar recibo digital |

---

## Biblioteca

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/library/books | Listar livros |
| POST | /api/escolar/library/books | Cadastrar livro |
| GET | /api/escolar/library/loans | Listar emprestimos |
| POST | /api/escolar/library/loans | Registar emprestimo |
| POST | /api/escolar/library/loans/{id}/return | Confirmar devolucao |

---

## Comunicacao e Dashboard

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/messages | Listar mensagens |
| POST | /api/escolar/messages | Criar comunicado |
| POST | /api/escolar/messages/{id}/publish | Publicar comunicado |
| GET | /api/escolar/dashboard/direction | KPIs da direccao |
| GET | /api/escolar/reports/academic-summary | Resumo academico |
| GET | /api/escolar/reports/financial-summary | Resumo financeiro |
| GET | /api/escolar/reports/delinquency | Relatorio de inadimplencia |
