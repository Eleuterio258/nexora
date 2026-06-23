# API — Modulo Faturacao

## Series Documentais

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/series | Listar series por tipo e ano |
| POST | /api/faturacao/series | Criar serie documental |
| GET | /api/faturacao/series/{id} | Obter serie com sequencia actual |
| PUT | /api/faturacao/series/{id} | Actualizar serie |
| POST | /api/faturacao/series/{id}/activar | Activar serie |
| POST | /api/faturacao/series/{id}/desactivar | Desactivar serie |

---

## Orcamentos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/quotes | Listar orcamentos (filtros: status, customer_id, data) |
| POST | /api/faturacao/quotes | Criar orcamento |
| GET | /api/faturacao/quotes/{id} | Obter orcamento com linhas |
| PUT | /api/faturacao/quotes/{id} | Actualizar orcamento (so em rascunho) |
| DELETE | /api/faturacao/quotes/{id} | Eliminar orcamento em rascunho |
| POST | /api/faturacao/quotes/{id}/enviar | Enviar orcamento ao cliente |
| POST | /api/faturacao/quotes/{id}/aprovar | Marcar como aprovado |
| POST | /api/faturacao/quotes/{id}/rejeitar | Marcar como rejeitado (motivo) |
| POST | /api/faturacao/quotes/{id}/converter | Converter em encomenda de venda |
| POST | /api/faturacao/quotes/{id}/items | Adicionar linha ao orcamento |
| PUT | /api/faturacao/quotes/{id}/items/{item_id} | Actualizar linha |
| DELETE | /api/faturacao/quotes/{id}/items/{item_id} | Remover linha |

---

## Encomendas de Venda

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/orders | Listar encomendas (filtros: status, customer_id, data) |
| POST | /api/faturacao/orders | Criar encomenda |
| GET | /api/faturacao/orders/{id} | Obter encomenda com linhas e entregas |
| PUT | /api/faturacao/orders/{id} | Actualizar encomenda (so em rascunho) |
| POST | /api/faturacao/orders/{id}/confirmar | Confirmar encomenda (valida stock) |
| POST | /api/faturacao/orders/{id}/cancelar | Cancelar encomenda (com motivo) |
| POST | /api/faturacao/orders/{id}/items | Adicionar linha |
| PUT | /api/faturacao/orders/{id}/items/{item_id} | Actualizar linha |
| DELETE | /api/faturacao/orders/{id}/items/{item_id} | Remover linha |

---

## Guias de Remessa

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/deliveries | Listar guias (filtros: sales_order_id, status) |
| POST | /api/faturacao/deliveries | Criar guia a partir de encomenda |
| GET | /api/faturacao/deliveries/{id} | Obter guia com itens |
| POST | /api/faturacao/deliveries/{id}/confirmar | Confirmar entrega (actualiza stock) |
| POST | /api/faturacao/deliveries/{id}/cancelar | Cancelar guia |
| GET | /api/faturacao/deliveries/{id}/pdf | Exportar guia em PDF |

---

## Faturas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/invoices | Listar faturas (filtros: status, customer_id, data, vencidas) |
| POST | /api/faturacao/invoices | Criar fatura (em rascunho) |
| GET | /api/faturacao/invoices/{id} | Obter fatura com linhas, impostos, descontos e recibos |
| PUT | /api/faturacao/invoices/{id} | Actualizar fatura em rascunho |
| POST | /api/faturacao/invoices/{id}/emitir | Emitir fatura (numero definitivo, imutavel) |
| POST | /api/faturacao/invoices/{id}/cancelar | Cancelar fatura (requer nota de credito) |
| POST | /api/faturacao/invoices/{id}/items | Adicionar linha (so em rascunho) |
| PUT | /api/faturacao/invoices/{id}/items/{item_id} | Actualizar linha (so em rascunho) |
| DELETE | /api/faturacao/invoices/{id}/items/{item_id} | Remover linha (so em rascunho) |
| GET | /api/faturacao/invoices/{id}/pdf | Exportar fatura em PDF |
| GET | /api/faturacao/invoices/vencidas | Faturas vencidas com saldo pendente |

---

## Recibos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/receipts | Listar recibos (filtros: invoice_id, status, data) |
| POST | /api/faturacao/receipts | Registar recibo de pagamento |
| GET | /api/faturacao/receipts/{id} | Obter recibo |
| POST | /api/faturacao/receipts/{id}/confirmar | Confirmar recibo (actualiza saldo da fatura) |
| POST | /api/faturacao/receipts/{id}/cancelar | Cancelar recibo (com motivo) |
| GET | /api/faturacao/receipts/{id}/pdf | Exportar recibo em PDF |

---

## Notas de Credito

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/credit-notes | Listar notas de credito (filtros: invoice_id, status) |
| POST | /api/faturacao/credit-notes | Criar nota de credito |
| GET | /api/faturacao/credit-notes/{id} | Obter nota de credito com linhas |
| PUT | /api/faturacao/credit-notes/{id} | Actualizar (so em rascunho) |
| POST | /api/faturacao/credit-notes/{id}/emitir | Emitir nota de credito |
| POST | /api/faturacao/credit-notes/{id}/aplicar | Aplicar como credito na fatura original |
| POST | /api/faturacao/credit-notes/{id}/cancelar | Cancelar nota de credito |
| GET | /api/faturacao/credit-notes/{id}/pdf | Exportar em PDF |

---

## Devolucoes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/returns | Listar devolucoes |
| POST | /api/faturacao/returns | Registar devolucao fisica |
| GET | /api/faturacao/returns/{id} | Obter devolucao com itens |
| POST | /api/faturacao/returns/{id}/receber | Confirmar recepcao fisica (actualiza stock) |
| POST | /api/faturacao/returns/{id}/processar | Processar devolucao (emite nota de credito associada) |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/faturacao/reports/sales-summary | Resumo de vendas por periodo |
| GET | /api/faturacao/reports/revenue-by-customer | Facturacao por cliente |
| GET | /api/faturacao/reports/revenue-by-product | Facturacao por produto |
| GET | /api/faturacao/reports/aging-receivables | Antiguidade de saldos em divida |
| GET | /api/faturacao/reports/tax-summary | Resumo de IVA por periodo (para declaracao fiscal) |
| GET | /api/faturacao/reports/top-customers | Top N clientes por valor facturado |
