# API — Submodulo Financeiro Escolar

## Planos de Cobranca

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/fee-plans | Listar planos (filtros: year_id, tipo_taxa, activo) |
| POST | /api/escolar/fee-plans | Criar plano de cobranca (matricula, propina, exame, etc.) |
| GET | /api/escolar/fee-plans/{id} | Obter plano com valor e periodicidade |
| PUT | /api/escolar/fee-plans/{id} | Actualizar plano |
| POST | /api/escolar/fee-plans/{id}/desactivar | Desactivar plano |

---

## Cobrancas de Alunos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/student-invoices | Listar cobrancas (filtros: enrollment_id, status, vencimento) |
| POST | /api/escolar/student-invoices | Gerar cobranca para aluno com entidade e referencia |
| GET | /api/escolar/student-invoices/{id} | Obter cobranca com valor_pendente e historico |
| POST | /api/escolar/student-invoices/{id}/desconto | Aplicar desconto ou bolsa de estudo |
| POST | /api/escolar/student-invoices/{id}/cancelar | Cancelar cobranca |
| POST | /api/escolar/student-invoices/gerar-lote | Gerar cobrancas mensais em lote para uma turma/serie |

---

## Pagamentos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/escolar/payments | Listar pagamentos (filtros: invoice_id, estado, canal) |
| POST | /api/escolar/payments | Registar pagamento manual (caixa, transferencia) |
| GET | /api/escolar/payments/{id} | Obter pagamento e estado de conciliacao |
| GET | /api/escolar/payments/{id}/receipt | Gerar recibo digital |
| POST | /api/escolar/payments/callback | Receber callback de gateway (M-Pesa, e-Mola, banco) |
