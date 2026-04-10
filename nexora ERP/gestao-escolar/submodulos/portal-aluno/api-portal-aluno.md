# API — Submodulo Portal do Aluno

> Acesso restrito ao aluno autenticado. Todos os endpoints devolvem apenas dados do proprio aluno.

## Perfil e Matricula

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/aluno/perfil | Obter dados do proprio aluno |
| GET | /api/portal/aluno/matricula | Obter matricula activa no ano lectivo corrente |

---

## Academico

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/aluno/boletim | Obter boletim com notas e medias por periodo |
| GET | /api/portal/aluno/boletim/anual | Obter boletim anual consolidado |
| GET | /api/portal/aluno/frequencia | Consultar frequencia por disciplina e periodo |

---

## Financeiro

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/aluno/cobrancas | Listar cobrancas com estado e valor pendente |
| GET | /api/portal/aluno/cobrancas/{id} | Obter cobranca com entidade e referencia de pagamento |
| GET | /api/portal/aluno/pagamentos/{id}/recibo | Descarregar recibo de pagamento |

---

## Comunicacao

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/aluno/comunicados | Listar comunicados dirigidos ao aluno ou turma |
