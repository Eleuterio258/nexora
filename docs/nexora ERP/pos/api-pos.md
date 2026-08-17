# API — Modulo POS

## Terminais

> Permissão: `pos:gerir_terminais`

| Metodo | Rota | Descricao |
| --- | --- | --- |
| GET | /api/pos/terminals | Listar terminais (filtros: ativo, warehouse_id, caixa_id, page, limit) |
| POST | /api/pos/terminals | Criar terminal |
| GET | /api/pos/terminals/{id} | Obter terminal |
| PUT | /api/pos/terminals/{id} | Actualizar terminal |
| DELETE | /api/pos/terminals/{id} | Arquivar terminal (soft-delete) |
| POST | /api/pos/terminals/{id}/activar | Activar terminal |
| POST | /api/pos/terminals/{id}/desactivar | Desactivar terminal |
| GET | /api/pos/terminals/{id}/sessao-activa | Obter sessao aberta do terminal |

### Filtros do listar

| Parametro | Tipo | Descricao |
| --- | --- | --- |
| `ativo` | boolean | Filtrar por estado ativo/inativo |
| `warehouse_id` | int | Filtrar por armazém |
| `caixa_id` | int | Filtrar por caixa da tesouraria |
| `page` | int | Página (default 1) |
| `limit` | int | Tamanho da página (default 20, max 100) |

### Criar / Actualizar terminal

```json
{
  "codigo": "CAIXA-01",
  "nome": "Caixa Principal",
  "warehouse_id": 5,
  "caixa_id": 3,
  "activation_code": "123456"
}
```

> `activation_code` é obrigatório apenas na criação.

### Resposta de terminal

```json
{
  "id": 1,
  "codigo": "CAIXA-01",
  "nome": "Caixa Principal",
  "warehouse_id": 5,
  "caixa_id": 3,
  "user_id": 42,
  "activo": true,
  "created_at": "2026-08-12T08:00:00Z",
  "updated_at": "2026-08-12T08:00:00Z"
}
```

### Regras

- O `codigo` é único por tenant.
- `DELETE /api/pos/terminals/{id}` só é permitido se o terminal **não tiver sessões** associadas. A conta sintética do terminal é desactivada.
- Terminais arquivados (`deleted_at IS NOT NULL`) não aparecem em listagens.

---

## Sessoes de Caixa

| Metodo | Rota | Descricao | Permissão |
| --- | --- | --- | --- |
| GET | `/api/pos/sessions` | Listar sessoes (com filtros) | `pos:ver` / `pos:supervisionar` / `pos:relatorios` |
| POST | `/api/pos/sessions` | Abrir sessao | `pos:abrir_sessao` + humano |
| GET | `/api/pos/sessions/atual` | Obter sessao aberta do utilizador | `pos:operar_pos` |
| GET | `/api/pos/sessions/{id}` | Obter sessao por ID | `pos:ver` / `pos:supervisionar` / `pos:relatorios` |
| POST | `/api/pos/sessions/{id}/fechar` | Fechar sessao | `pos:fechar_sessao` (própria) ou `pos:supervisionar_pos` / `pos:fechar_outra_sessao` (de outro) + humano |
| GET | `/api/pos/sessions/{id}/fecho` | Resumo de fecho | `pos:ver` / `pos:relatorios` |
| GET | `/api/pos/sessions/{id}/movimentacoes` | Listar movimentos | `pos:ver` / `pos:supervisionar` |
| POST | `/api/pos/sessions/{id}/movimentacoes` | Registar movimento | `pos:movimentar_caixa` + humano |

### Filtros do listar

```http
GET /api/pos/sessions?status=aberta&terminal_id=1&user_id=5&data_inicio=2026-08-01&data_fim=2026-08-31&page=1&limit=20
```

| Parametro | Tipo | Descricao |
|---|---|---|
| `status` | string | `aberta` ou `fechada` |
| `terminal_id` | int | Filtrar por terminal |
| `user_id` | int | Filtrar por operador |
| `funcionario_id` | int | Filtrar por funcionário |
| `data_inicio` | date | Sessões a partir de |
| `data_fim` | date | Sessões até |
| `page` | int | Página |
| `limit` | int | Tamanho da página |

### Regras

- Um operador só pode ter **uma sessão aberta de cada vez**.
- Um terminal só pode ter **uma sessão aberta de cada vez**.
- Só o **dono da sessão** pode fechar a própria sessão.
- Supervisores podem fechar sessões de outros operadores com `pos:supervisionar_pos` ou `pos:fechar_outra_sessao`.
- Operadores normais só visualizam as próprias sessões no listar.

---

## Vendas

| Metodo | Rota | Descricao | Permissão |
| --- | --- | --- | --- |
| POST | `/api/pos/sales` | Registar venda completa (itens + pagamentos) | `pos:registar_venda` + humano |
| GET | `/api/pos/sales/{id}` | Obter venda com itens e pagamentos | `pos:operar_pos` / `pos:ver_vendas` / `pos:supervisionar` / `pos:relatorios` |
| GET | `/api/pos/sales` | Listar vendas | `pos:operar_pos` / `pos:ver_vendas` / `pos:supervisionar` / `pos:relatorios` |
| POST | `/api/pos/sales/{id}/cancelar` | Cancelar venda | `pos:cancelar_venda` (própria) ou `pos:supervisionar_pos` (de outro) + humano |
| GET | `/api/pos/sales/{id}/recibo` | Dados formatados para recibo | `pos:operar_pos` / `pos:ver_vendas` / `pos:supervisionar` / `pos:relatorios` |
| POST | `/api/pos/sales/{id}/estorno-parcial` | Estorno parcial de venda | `pos:supervisionar_pos` + humano |
| GET | `/api/pos/sales/{id}/estornos` | Listar estornos | `pos:operar_pos` / `pos:ver_vendas` / `pos:supervisionar` / `pos:relatorios` |

### Filtros do listar

```http
GET /api/pos/sales?status=concluida&pos_session_id=1&terminal_id=5&user_id=10&data_inicio=2026-08-01&data_fim=2026-08-31&page=1&limit=20&q=VD0001
```

| Parametro | Tipo | Descricao |
|---|---|---|
| `status` | string | `concluida` / `cancelada` |
| `pos_session_id` | int | Filtrar por sessão |
| `terminal_id` | int | Filtrar por terminal |
| `user_id` | int | Filtrar por operador (created_by) |
| `data_inicio` | date | Vendas a partir de |
| `data_fim` | date | Vendas até |
| `q` | string | Busca por número, client_reference ou referência de pagamento |
| `page` / `limit` | int | Paginação |

### Regras

- Apenas o **dono da venda** pode cancelar com `pos:cancelar_venda`.
- Supervisores podem cancelar vendas de outros com `pos:supervisionar_pos`.
- **Motivo é obrigatório** no cancelamento.
- Operadores normais só visualizam as próprias vendas no listar.

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
