# API — Submodulo Gestao de Alunos

## Alunos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/students | Listar alunos (filtros: status, search) |
| POST | /api/escolar/students | Cadastrar aluno |
| GET | /api/escolar/students/{id} | Obter aluno com encarregados e matriculas |
| PUT | /api/escolar/students/{id} | Actualizar dados do aluno |
| POST | /api/escolar/students/{id}/transferir | Registar transferencia de saida |

---

## Encarregados

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/students/{student_id}/guardians | Listar encarregados do aluno |
| POST | /api/escolar/students/{student_id}/guardians | Adicionar encarregado |
| PUT | /api/escolar/students/{student_id}/guardians/{id} | Actualizar dados do encarregado |
| DELETE | /api/escolar/students/{student_id}/guardians/{id} | Remover encarregado |

---

## Matriculas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/enrollments | Listar matriculas (filtros: year_id, class_id, estado) |
| POST | /api/escolar/enrollments | Efectuar matricula ou rematricula |
| GET | /api/escolar/enrollments/{id} | Obter matricula com dados do aluno e turma |
| PUT | /api/escolar/enrollments/{id} | Actualizar dados da matricula |
| POST | /api/escolar/enrollments/{id}/suspender | Suspender matricula (com motivo) |
| POST | /api/escolar/enrollments/{id}/reactivar | Reactivar matricula suspensa |
| POST | /api/escolar/enrollments/{id}/transferir | Transferir para outra turma no mesmo ano |
| POST | /api/escolar/enrollments/{id}/concluir | Marcar matricula como concluida |
| POST | /api/escolar/enrollments/{id}/cancelar | Cancelar matricula |
