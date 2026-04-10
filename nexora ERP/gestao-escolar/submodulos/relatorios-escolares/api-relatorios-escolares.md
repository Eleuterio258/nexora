# API — Submodulo Relatorios Escolares

## Dashboard da Direccao

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/dashboard/direction | KPIs gerais: total alunos, turmas, professores, propinas em atraso |

---

## Relatorios Academicos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/reports/academic-summary | Resumo academico por turma e periodo (medias, aprovados, reprovados) |
| GET | /api/escolar/reports/attendance-summary | Resumo de frequencia por turma e disciplina |
| GET | /api/escolar/reports/grade-distribution | Distribuicao de notas por avaliacao e turma |
| GET | /api/escolar/reports/top-students | Lista dos melhores alunos por turma e serie |

---

## Relatorios Financeiros

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/reports/financial-summary | Resumo financeiro: emitido, pago e pendente por periodo |
| GET | /api/escolar/reports/delinquency | Relatorio de inadimplencia com alunos e valores em atraso |
| GET | /api/escolar/reports/payments-by-channel | Pagamentos agrupados por canal (caixa, M-Pesa, transferencia) |
