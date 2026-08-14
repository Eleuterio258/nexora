# Análise: Endpoints do Terminal POS

**Data:** 2026-08-12  
**Âmbito:** Endpoints REST para gestão de terminais POS (`/api/pos/terminals`)  
**Objetivo:** Mapear endpoints existentes, identificar gaps e propor melhorias para o CRUD de terminais.

---

## 1. Resumo executivo

A gestão de terminais POS é uma funcionalidade crítica do módulo POS. Atualmente existem endpoints básicos para listar, criar, ativar e desativar terminais, mas **faltam operações comuns de CRUD** como obter um terminal por ID, atualizar dados completos e remover (soft-delete).

Esta análise propõe um conjunto completo de endpoints REST para terminais, alinhado com as permissões granulares já existentes (`pos:gerir_terminais`).

---

## 2. Endpoints atuais

| Método | Endpoint | Handler | Descrição | Permissão |
|---|---|---|---|---|
| GET | `/api/pos/terminals` | `pos.ListarTerminais` | Listar terminais do tenant | `pos:gerir_terminais` |
| POST | `/api/pos/terminals` | `pos.CriarTerminal` | Criar novo terminal | `pos:gerir_terminais` |
| POST | `/api/pos/terminals/{id}/activar` | `pos.ActivarTerminal` | Ativar terminal | `pos:gerir_terminais` |
| POST | `/api/pos/terminals/{id}/desactivar` | `pos.DesactivarTerminal` | Desativar terminal | `pos:gerir_terminais` |

### Código atual no router

```go
// Gerir terminais
r.Group(func(r chi.Router) {
    r.Use(mw.RequirePermission(db, "pos", "gerir_terminais"))
    r.Route("/terminais", func(r chi.Router) {
        r.Get("/", pos.ListarTerminais)
        r.Post("/", pos.CriarTerminal)
        r.Post("/{id}/activar", pos.ActivarTerminal)
        r.Post("/{id}/desactivar", pos.DesactivarTerminal)
    })
})
```

### Handler atual

O handler `pos.go` já contém:
- `ListarTerminais` — lista com `id, codigo, nome, warehouse_id, caixa_id, activo`
- `CriarTerminal` — cria terminal + conta de utilizador sintética
- `ActivarTerminal` / `DesactivarTerminal` — altera campo `activo`

---

## 3. Gaps identificados

| Operação | Endpoint | Estado | Justificativa |
|---|---|---|---|
| Obter terminal por ID | `GET /api/pos/terminals/{id}` | ❌ Não existe | Necessário para edição e detalhe |
| Atualizar terminal | `PUT /api/pos/terminals/{id}` | ❌ Não existe | Só é possível ativar/desativar; não editar nome, armazém, caixa |
| Sessão ativa do terminal | `GET /api/pos/terminals/{id}/sessao-activa` | ❌ Não implementado | Documentado mas não existe no router |
| Soft-delete terminal | `DELETE /api/pos/terminals/{id}` | ❌ Não existe | Desativar não remove; pode ser necessário arquivar |
| Validar código único | — | ⚠️ Parcial | Existe validação no INSERT, mas não no UPDATE |
| Listar com filtros | `GET /api/pos/terminals?ativo=&warehouse_id=` | ⚠️ Parcial | Documentado mas não implementado |

---

## 4. Endpoints propostos

### 4.1 CRUD completo

| Método | Endpoint | Descrição | Permissão |
|---|---|---|---|
| GET | `/api/pos/terminals` | Listar terminais (com filtros) | `pos:gerir_terminais` |
| POST | `/api/pos/terminals` | Criar terminal | `pos:gerir_terminais` |
| GET | `/api/pos/terminals/{id}` | Obter terminal por ID | `pos:gerir_terminais` |
| PUT | `/api/pos/terminals/{id}` | Atualizar terminal | `pos:gerir_terminais` |
| POST | `/api/pos/terminals/{id}/activar` | Ativar terminal | `pos:gerir_terminais` |
| POST | `/api/pos/terminals/{id}/desactivar` | Desativar terminal | `pos:gerir_terminais` |
| DELETE | `/api/pos/terminals/{id}` | Arquivar/soft-delete terminal | `pos:gerir_terminais` |
| GET | `/api/pos/terminals/{id}/sessao-activa` | Obter sessão aberta do terminal | `pos:gerir_terminais` |

### 4.2 Filtros no listar

```http
GET /api/pos/terminals?ativo=true&warehouse_id=123
```

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `ativo` | bool | Filtrar por estado ativo/inativo |
| `warehouse_id` | int | Filtrar por armazém |
| `caixa_id` | int | Filtrar por caixa da tesouraria |
| `page` | int | Paginação |
| `limit` | int | Tamanho da página (max 100) |

### 4.3 Payloads

#### Criar/Atualizar terminal

```json
{
  "codigo": "CAIXA-01",
  "nome": "Caixa Principal",
  "warehouse_id": 5,
  "caixa_id": 3,
  "activation_code": "123456"
}
```

> `activation_code` só é obrigatório na criação.

#### Resposta de terminal

```json
{
  "id": 1,
  "codigo": "CAIXA-01",
  "nome": "Caixa Principal",
  "warehouse_id": 5,
  "caixa_id": 3,
  "activo": true,
  "created_at": "2026-08-12T08:00:00Z",
  "updated_at": "2026-08-12T08:00:00Z"
}
```

---

## 5. Implementação proposta

### 5.1 Novos handlers em `backend/internal/modules/pos/handlers/pos.go`

```go
// ObterTerminal devolve um terminal pelo ID.
func (h *Handler) ObterTerminal(w http.ResponseWriter, r *http.Request) {
    user := mw.GetUser(r)
    id := chi.URLParam(r, "id")

    type Row struct {
        ID          int64      `json:"id"`
        Codigo      string     `json:"codigo"`
        Nome        string     `json:"nome"`
        WarehouseID *int64     `json:"warehouse_id"`
        CaixaID     *int64     `json:"caixa_id"`
        Activo      bool       `json:"activo"`
        CreatedAt   time.Time  `json:"created_at"`
        UpdatedAt   time.Time  `json:"updated_at"`
    }
    var t Row
    err := h.db.QueryRow(r.Context(), `
        SELECT id, codigo, nome, warehouse_id, caixa_id, activo, created_at, updated_at
          FROM pos_terminals
         WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
        Scan(&t.ID, &t.Codigo, &t.Nome, &t.WarehouseID, &t.CaixaID, &t.Activo, &t.CreatedAt, &t.UpdatedAt)
    if err == pgx.ErrNoRows {
        jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
        return
    }
    if err != nil {
        jsonErr(w, "Erro interno", http.StatusInternalServerError)
        return
    }
    jsonOK(w, t, http.StatusOK)
}

// ActualizarTerminal actualiza nome, warehouse_id e caixa_id de um terminal.
func (h *Handler) ActualizarTerminal(w http.ResponseWriter, r *http.Request) {
    user := mw.GetUser(r)
    id := chi.URLParam(r, "id")

    var body struct {
        Nome        string `json:"nome"`
        WarehouseID *int64 `json:"warehouse_id"`
        CaixaID     *int64 `json:"caixa_id"`
    }
    if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
        jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
        return
    }

    tag, err := h.db.Exec(r.Context(), `
        UPDATE pos_terminals
           SET nome=$1, warehouse_id=$2, caixa_id=$3, updated_at=NOW()
         WHERE id=$4 AND tenant_id=$5`,
        body.Nome, body.WarehouseID, body.CaixaID, id, user.TenantID)
    if err != nil {
        jsonErr(w, "Erro interno", http.StatusInternalServerError)
        return
    }
    if tag.RowsAffected() == 0 {
        jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
        return
    }
    w.WriteHeader(http.StatusNoContent)
}

// ArquivarTerminal faz soft-delete de um terminal (apenas se não tiver sessões).
func (h *Handler) ArquivarTerminal(w http.ResponseWriter, r *http.Request) {
    user := mw.GetUser(r)
    id := chi.URLParam(r, "id")

    var temSessoes bool
    err := h.db.QueryRow(r.Context(), `
        SELECT EXISTS(SELECT 1 FROM pos_sessions WHERE terminal_id=$1)`, id).Scan(&temSessoes)
    if err != nil {
        jsonErr(w, "Erro interno", http.StatusInternalServerError)
        return
    }
    if temSessoes {
        jsonErr(w, "Não é possível remover terminal com sessões associadas", http.StatusConflict)
        return
    }

    tag, err := h.db.Exec(r.Context(), `
        UPDATE pos_terminals SET activo=false, deleted_at=NOW(), updated_at=NOW()
         WHERE id=$1 AND tenant_id=$2 AND deleted_at IS NULL`, id, user.TenantID)
    if err != nil {
        jsonErr(w, "Erro interno", http.StatusInternalServerError)
        return
    }
    if tag.RowsAffected() == 0 {
        jsonErr(w, "Terminal não encontrado", http.StatusNotFound)
        return
    }
    w.WriteHeader(http.StatusNoContent)
}

// ObterSessaoAtivaDoTerminal devolve a sessão aberta de um terminal específico.
func (h *Handler) ObterSessaoAtivaDoTerminal(w http.ResponseWriter, r *http.Request) {
    user := mw.GetUser(r)
    id := chi.URLParam(r, "id")

    type Row struct {
        ID            int64     `json:"id"`
        UserID        int64     `json:"user_id"`
        FuncionarioID *int64    `json:"funcionario_id"`
        Status        string    `json:"status"`
        OpeningAmount float64   `json:"opening_amount"`
        OpenedAt      time.Time `json:"opened_at"`
    }
    var s Row
    err := h.db.QueryRow(r.Context(), `
        SELECT id, user_id, funcionario_id, status, opening_amount, opened_at
          FROM pos_sessions
         WHERE tenant_id=$1 AND terminal_id=$2 AND status='aberta'
         LIMIT 1`, user.TenantID, id).
        Scan(&s.ID, &s.UserID, &s.FuncionarioID, &s.Status, &s.OpeningAmount, &s.OpenedAt)
    if err == pgx.ErrNoRows {
        jsonOK(w, map[string]any{"sessao": nil}, http.StatusOK)
        return
    }
    if err != nil {
        jsonErr(w, "Erro interno", http.StatusInternalServerError)
        return
    }
    jsonOK(w, s, http.StatusOK)
}
```

### 5.2 Atualização do router

```go
// Gerir terminais
r.Group(func(r chi.Router) {
    r.Use(mw.RequirePermission(db, "pos", "gerir_terminais"))
    r.Route("/terminais", func(r chi.Router) {
        r.Get("/", pos.ListarTerminais)
        r.Post("/", pos.CriarTerminal)
        r.Route("/{id}", func(r chi.Router) {
            r.Get("/", pos.ObterTerminal)
            r.Put("/", pos.ActualizarTerminal)
            r.Delete("/", pos.ArquivarTerminal)
            r.Post("/activar", pos.ActivarTerminal)
            r.Post("/desactivar", pos.DesactivarTerminal)
            r.Get("/sessao-activa", pos.ObterSessaoAtivaDoTerminal)
        })
    })
})
```

### 5.3 Schema — adicionar `deleted_at`

```sql
ALTER TABLE pos_terminals ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_pos_terminals_deleted_at ON pos_terminals(deleted_at) WHERE deleted_at IS NULL;
```

E atualizar `ListarTerminais` para ignorar `deleted_at IS NOT NULL`.

---

## 6. Validações e regras de negócio

| Regra | Implementação |
|---|---|
| Código único por tenant | `UNIQUE (tenant_id, codigo)` já existe + validação no handler |
| Nome obrigatório | Validar no handler |
| Warehouse/caixa opcionais mas devem existir | Verificar FK se preenchidos |
| Não remover terminal com sessões | Verificar `pos_sessions` antes do soft-delete |
| Terminal desativado não opera | Verificar `activo=true` no login e abertura de sessão |
| Conta de utilizador sintética | Criar no `CriarTerminal`; desativar no `ArquivarTerminal` |

---

## 7. Integração com portais propostos

No portal **Admin** (`/pos/admin/terminais`), os endpoints acima seriam usados para:
- Listar terminais: `GET /api/pos/terminals`
- Criar terminal: `POST /api/pos/terminals`
- Editar terminal: `PUT /api/pos/terminals/{id}`
- Ativar/desativar: `POST /api/pos/terminals/{id}/activar|desactivar`
- Remover: `DELETE /api/pos/terminals/{id}`
- Ver sessão ativa: `GET /api/pos/terminals/{id}/sessao-activa`

---

## 8. Conclusão

Os endpoints de terminal POS precisam de um CRUD completo para suportar a gestão eficiente do POS. A implementação proposta é simples, reutiliza os handlers existentes e alinha-se com as permissões granulares já definidas (`pos:gerir_terminais`).

Próximos passos recomendados:
1. Adicionar handlers `ObterTerminal`, `ActualizarTerminal`, `ArquivarTerminal`, `ObterSessaoAtivaDoTerminal`.
2. Atualizar `backend/internal/router/router.go`.
3. Adicionar coluna `deleted_at` à tabela `pos_terminals`.
4. Atualizar `docs/nexora ERP/pos/api-pos.md`.
