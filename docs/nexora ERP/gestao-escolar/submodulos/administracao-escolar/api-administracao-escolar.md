# API — Submodulo Administracao Escolar

## Anos Lectivos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/years | Listar anos lectivos (filtro: status) |
| POST | /api/escolar/years | Criar ano lectivo |
| GET | /api/escolar/years/{id} | Obter ano lectivo com periodos |
| PUT | /api/escolar/years/{id} | Actualizar ano lectivo |
| POST | /api/escolar/years/{id}/activar | Activar ano lectivo (um activo por vez) |
| POST | /api/escolar/years/{id}/encerrar | Encerrar ano lectivo |

---

## Periodos Lectivos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/years/{year_id}/terms | Listar periodos do ano lectivo |
| POST | /api/escolar/years/{year_id}/terms | Criar periodo lectivo |
| GET | /api/escolar/years/{year_id}/terms/{id} | Obter periodo |
| PUT | /api/escolar/years/{year_id}/terms/{id} | Actualizar periodo |
| POST | /api/escolar/years/{year_id}/terms/{id}/fechar | Fechar periodo lectivo |

---

## Turmas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/classes | Listar turmas (filtros: year_id, serie, turno) |
| POST | /api/escolar/classes | Criar turma |
| GET | /api/escolar/classes/{id} | Obter turma com lista de alunos |
| PUT | /api/escolar/classes/{id} | Actualizar turma (sala, capacidade, turno) |
| POST | /api/escolar/classes/{id}/director | Definir professor director de turma |

---

## Disciplinas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/subjects | Listar disciplinas activas |
| POST | /api/escolar/subjects | Criar disciplina |
| GET | /api/escolar/subjects/{id} | Obter disciplina |
| PUT | /api/escolar/subjects/{id} | Actualizar disciplina |
| POST | /api/escolar/subjects/{id}/desactivar | Desactivar disciplina |
