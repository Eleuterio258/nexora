# API — Submodulo Gestao de Professores

## Professores

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/teachers | Listar professores (filtros: status, especialidade) |
| POST | /api/escolar/teachers | Cadastrar professor |
| GET | /api/escolar/teachers/{id} | Obter professor com atribuicoes activas |
| PUT | /api/escolar/teachers/{id} | Actualizar dados do professor |
| POST | /api/escolar/teachers/{id}/suspender | Suspender professor |
| POST | /api/escolar/teachers/{id}/reactivar | Reactivar professor |

---

## Atribuicoes por Turma e Disciplina

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/teacher-assignments | Listar atribuicoes (filtros: year_id, class_id, teacher_id) |
| POST | /api/escolar/teacher-assignments | Atribuir professor a turma/disciplina no ano lectivo |
| GET | /api/escolar/teacher-assignments/{id} | Obter atribuicao |
| PUT | /api/escolar/teacher-assignments/{id} | Actualizar carga horaria semanal |
| POST | /api/escolar/teacher-assignments/{id}/encerrar | Encerrar atribuicao |
