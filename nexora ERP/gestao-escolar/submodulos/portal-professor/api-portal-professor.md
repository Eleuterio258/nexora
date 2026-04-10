# API — Submodulo Portal do Professor

> Acesso restrito ao professor autenticado. Endpoints de escrita limitados as turmas e disciplinas atribuidas.

## Minhas Turmas e Disciplinas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/professor/atribuicoes | Listar turmas e disciplinas atribuidas no ano lectivo activo |
| GET | /api/portal/professor/turmas/{class_id} | Obter turma com lista de alunos matriculados |
| GET | /api/portal/professor/turmas/{class_id}/frequencia | Resumo de frequencia da turma por disciplina |

---

## Frequencia

| Metodo | Rota | Descricao |
| --- | --- | --- |
| POST | /api/portal/professor/frequencia | Lancar frequencia de uma aula |
| PUT | /api/portal/professor/frequencia/{id} | Corrigir registo de frequencia |

---

## Avaliacoes e Notas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/professor/avaliacoes | Listar avaliacoes das minhas disciplinas |
| POST | /api/portal/professor/avaliacoes | Criar avaliacao (teste, trabalho, oral, projecto) |
| PUT | /api/portal/professor/avaliacoes/{id} | Actualizar avaliacao |
| GET | /api/portal/professor/notas | Listar notas lancadas por avaliacao |
| POST | /api/portal/professor/notas | Lancar nota de aluno |
| PUT | /api/portal/professor/notas/{id} | Corrigir nota |
| POST | /api/portal/professor/notas/batch | Lancar notas em lote para toda a turma |

---

## Comunicacao

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/professor/comunicados | Listar comunicados dirigidos a professores ou turma |
