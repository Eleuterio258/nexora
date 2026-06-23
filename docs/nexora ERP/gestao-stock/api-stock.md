# API — Modulo Gestao de Stock

## Armazens

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/warehouses | Listar armazens |
| POST | /api/stock/warehouses | Criar armazem |
| GET | /api/stock/warehouses/{id} | Obter armazem |
| PUT | /api/stock/warehouses/{id} | Actualizar armazem |
| POST | /api/stock/warehouses/{id}/activar | Activar armazem |
| POST | /api/stock/warehouses/{id}/desactivar | Desactivar armazem |

### Localizacoes do Armazem

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/warehouses/{id}/locations | Listar localizacoes |
| POST | /api/stock/warehouses/{id}/locations | Criar localizacao (corredor, prateleira, etc.) |
| PUT | /api/stock/warehouses/{id}/locations/{loc_id} | Actualizar localizacao |
| DELETE | /api/stock/warehouses/{id}/locations/{loc_id} | Remover localizacao |

---

## Posicao de Stock

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/items | Posicao de stock (filtros: warehouse_id, product_id, abaixo_minimo) |
| GET | /api/stock/items/{id} | Obter posicao especifica (com reservas e lotes) |
| POST | /api/stock/items | Inicializar stock de produto num armazem |
| PUT | /api/stock/items/{id}/minimos | Definir stock minimo e maximo |

---

## Movimentos

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/movements | Listar movimentos (filtros: product_id, warehouse_id, tipo, data) |
| POST | /api/stock/movements | Registar movimento manual (entrada ou saida) |
| GET | /api/stock/movements/{id} | Obter movimento |

---

## Ajustes de Stock

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/adjustments | Listar ajustes (filtros: warehouse_id, tipo, data) |
| POST | /api/stock/adjustments | Criar ajuste (positivo ou negativo com motivo) |
| GET | /api/stock/adjustments/{id} | Obter ajuste |

---

## Transferencias entre Armazens

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/transfers | Listar transferencias (filtros: status, warehouse) |
| POST | /api/stock/transfers | Criar transferencia |
| GET | /api/stock/transfers/{id} | Obter transferencia com itens |
| POST | /api/stock/transfers/{id}/confirmar | Confirmar expedição (em_transito) |
| POST | /api/stock/transfers/{id}/receber | Confirmar recepcao (concluida, actualiza stock) |
| POST | /api/stock/transfers/{id}/cancelar | Cancelar transferencia |

---

## Reservas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/reservations | Listar reservas activas (filtros: product_id, reference_type) |
| POST | /api/stock/reservations | Criar reserva (chama fn_reservar_stock) |
| GET | /api/stock/reservations/{id} | Obter reserva |
| POST | /api/stock/reservations/{id}/liberar | Liberar reserva (chama fn_liberar_reserva) |
| POST | /api/stock/reservations/{id}/consumir | Consumir reserva ao confirmar venda (chama fn_consumir_reserva) |

---

## Lotes

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/batches | Listar lotes (filtros: product_id, a_expirar) |
| POST | /api/stock/batches | Registar lote (numero, fabricacao, validade, quantidade) |
| GET | /api/stock/batches/{id} | Obter lote |
| PUT | /api/stock/batches/{id} | Actualizar lote |
| GET | /api/stock/batches/a-expirar | Lotes que expiram nos proximos N dias |

---

## Numeros de Serie

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/serials | Listar numeros de serie (filtros: product_id, status) |
| POST | /api/stock/serials | Registar numero de serie |
| GET | /api/stock/serials/{serial} | Obter por numero de serie (pesquisa directa) |
| PUT | /api/stock/serials/{id}/status | Actualizar estado (disponivel, reservado, vendido, devolvido) |

---

## Contagens Fisicas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/counts | Listar contagens (filtros: warehouse_id, status) |
| POST | /api/stock/counts | Iniciar contagem fisica |
| GET | /api/stock/counts/{id} | Obter contagem com itens e divergencias |
| POST | /api/stock/counts/{id}/items | Lancar quantidade contada por produto |
| PUT | /api/stock/counts/{id}/items/{item_id} | Corrigir quantidade contada |
| POST | /api/stock/counts/{id}/fechar | Fechar e gerar ajustes automaticos das divergencias |
| POST | /api/stock/counts/{id}/cancelar | Cancelar contagem |

---

## Alertas

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/alerts | Listar alertas abertos (filtros: alert_type, warehouse_id) |
| POST | /api/stock/alerts/{id}/resolver | Marcar alerta como resolvido |
| POST | /api/stock/alerts/{id}/ignorar | Ignorar alerta |

---

## Relatorios

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/stock/reports/position | Posicao de stock por armazem e produto |
| GET | /api/stock/reports/movements-summary | Resumo de entradas e saidas por periodo |
| GET | /api/stock/reports/low-stock | Produtos abaixo do stock minimo |
| GET | /api/stock/reports/expiring-batches | Lotes a expirar por periodo |
| GET | /api/stock/reports/count-divergences | Divergencias da ultima contagem fisica |
| GET | /api/stock/reports/valuation | Valorizacao do stock (quantidade x custo medio) |
