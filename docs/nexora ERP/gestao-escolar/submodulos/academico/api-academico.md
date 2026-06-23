# API — Submodulo Academico

## Frequencia

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/attendance | Listar frequencias (filtros: assignment_id, enrollment_id, data) |
| POST | /api/escolar/attendance | Lancar frequencia de uma aula |
| PUT | /api/escolar/attendance/{id} | Corrigir registo de frequencia |
| GET | /api/escolar/attendance/resumo | Resumo de frequencia por aluno e disciplina no periodo |

---

## Avaliacoes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/grade-items | Listar avaliacoes (filtros: assignment_id, term_id, tipo) |
| POST | /api/escolar/grade-items | Criar avaliacao (teste, trabalho, oral, exame) |
| GET | /api/escolar/grade-items/{id} | Obter avaliacao com pesos |
| PUT | /api/escolar/grade-items/{id} | Actualizar avaliacao |
| DELETE | /api/escolar/grade-items/{id} | Remover avaliacao (sem notas lancadas) |

---

## Notas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/grades | Listar notas (filtros: grade_item_id, enrollment_id) |
| POST | /api/escolar/grades | Lancar nota de aluno numa avaliacao |
| PUT | /api/escolar/grades/{id} | Corrigir nota lancada |
| POST | /api/escolar/grades/batch | Lancar notas em lote para toda a turma |

---

## Boletins

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/report-cards/{enrollment_id} | Obter boletim do aluno por periodo (medias, faltas) |
| GET | /api/escolar/report-cards/{enrollment_id}/anual | Obter boletim anual consolidado |
