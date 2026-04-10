# API — Submodulo Cargos Escolares

## Cargos de Alunos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/student-roles | Listar cargos de alunos (filtros: enrollment_id, tipo_cargo, activo) |
| POST | /api/escolar/student-roles | Atribuir cargo ao aluno (chefe_turma, adjunto, higiene, etc.) |
| GET | /api/escolar/student-roles/{id} | Obter cargo do aluno |
| PUT | /api/escolar/student-roles/{id} | Actualizar vigencia do cargo |
| POST | /api/escolar/student-roles/{id}/revogar | Revogar cargo do aluno |

---

## Cargos de Professores

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/teacher-roles | Listar cargos de professores (filtros: teacher_id, tipo_cargo, activo) |
| POST | /api/escolar/teacher-roles | Atribuir cargo ao professor (director_turma, director_ciclo, etc.) |
| GET | /api/escolar/teacher-roles/{id} | Obter cargo do professor |
| PUT | /api/escolar/teacher-roles/{id} | Actualizar vigencia do cargo |
| POST | /api/escolar/teacher-roles/{id}/revogar | Revogar cargo do professor |
