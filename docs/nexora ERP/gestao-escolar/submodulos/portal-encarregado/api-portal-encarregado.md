# API — Submodulo Portal do Encarregado

> Acesso restrito ao encarregado autenticado. Dados limitados aos educandos sob sua responsabilidade.

## Educandos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/encarregado/educandos | Listar alunos sob responsabilidade do encarregado |
| GET | /api/portal/encarregado/educandos/{student_id} | Obter dados completos do educando |

---

## Acompanhamento Academico

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/encarregado/educandos/{student_id}/boletim | Obter boletim por periodo |
| GET | /api/portal/encarregado/educandos/{student_id}/boletim/anual | Obter boletim anual |
| GET | /api/portal/encarregado/educandos/{student_id}/frequencia | Consultar frequencia e faltas |

---

## Financeiro

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/encarregado/educandos/{student_id}/cobrancas | Listar cobrancas do educando |
| GET | /api/portal/encarregado/educandos/{student_id}/cobrancas/{id} | Obter cobranca com entidade e referencia |
| GET | /api/portal/encarregado/pagamentos/{id}/recibo | Descarregar recibo de pagamento |

---

## Comunicacao

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/portal/encarregado/comunicados | Listar comunicados dirigidos aos encarregados ou ao educando |
