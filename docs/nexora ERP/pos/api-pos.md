# API — Modulo POS

## Terminais

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/pos/terminals | Listar terminais (filtros: ativo, warehouse_id) |
| POST | /api/pos/terminals | Criar terminal |
| GET | /api/pos/terminals/{id} | Obter terminal |
| PUT | /api/pos/terminals/{id} | Actualizar terminal |
| POST | /api/pos/terminals/{id}/activar | Activar terminal |
| POST | /api/pos/terminals/{id}/desactivar | Desactivar terminal |
| GET | /api/pos/terminals/{id}/sessao-activa | Obter sessao aberta do terminal |

---

## Sessoes de Caixa

| Metodo | Rota | Descricao |
| --- | --- | --- |
| POST | /api/pos/sessions/abrir | Abrir sessao (terminal_id, saldo_inicial) |
| GET | /api/pos/sessions/{id} | Obter sessao |
| GET | /api/pos/sessions/{id}/resumo | Resumo da sessao (totais por metodo, movimentos) |
| POST | /api/pos/sessions/{id}/fechar | Fechar sessao (saldo_final_declarado, observacoes) |
| GET | /api/pos/sessions | Listar sessoes (filtros: terminal_id, user_id, status, data) |

---

## Vendas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| POST | /api/pos/sales | Registar venda completa (itens + pagamentos) |
| GET | /api/pos/sales/{id} | Obter venda com itens e pagamentos |
| GET | /api/pos/sales | Listar vendas (filtros: session_id, customer_id, data, status) |
| POST | /api/pos/sales/{id}/cancelar | Cancelar venda (motivo obrigatorio, estorna stock) |
| GET | /api/pos/sales/{id}/recibo | Dados formatados para impressao de recibo |

---

## Pagamentos da Venda

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/pos/sales/{id}/payments | Listar pagamentos da venda |
| POST | /api/pos/sales/{id}/payments | Adicionar metodo de pagamento a venda em rascunho |

---

## Devolucoes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| POST | /api/pos/returns | Registar devolucao (pos_sale_id, itens, tipo_reembolso) |
| GET | /api/pos/returns/{id} | Obter devolucao com itens |
| GET | /api/pos/returns | Listar devolucoes (filtros: session_id, pos_sale_id) |
| POST | /api/pos/returns/{id}/cancelar | Cancelar devolucao |

---

## Movimentos de Caixa

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/pos/sessions/{id}/cash-movements | Listar movimentos da sessao |
| POST | /api/pos/sessions/{id}/cash-movements | Registar entrada ou saida manual |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/pos/reports/sales-by-session | Vendas por sessao com totais por metodo |
| GET | /api/pos/reports/sales-by-terminal | Vendas por terminal e periodo |
| GET | /api/pos/reports/sales-by-product | Produtos mais vendidos por periodo |
| GET | /api/pos/reports/sales-by-hour | Distribuicao horaria de vendas |
| GET | /api/pos/reports/cash-closing | Resumo de fecho de caixa (para impressao) |
