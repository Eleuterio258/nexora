package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// Desconto POS autónomo (item 8 do plano) — distinto dos descontos por
// produto (produtos.product_discounts) e por cliente (gestao-clientes), que
// não se ligam entre si nem com o POS. Este é aplicável diretamente numa
// venda, tal como o PayCore Mobile já modela hoje.

func (h *Handler) ListarDescontos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("active"); v != "" {
		args = append(args, v == "true")
		where += " AND activo=$2"
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, nome, descricao, tipo, valor, valor_minimo, valor_maximo, valido_de, valido_ate, activo
		  FROM pos.pos_discounts WHERE `+where+` ORDER BY nome`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID          int64    `json:"id"`
		Nome        string   `json:"name"`
		Descricao   *string  `json:"description"`
		Tipo        string   `json:"type"`
		Valor       float64  `json:"value"`
		ValorMinimo *float64 `json:"min_amount"`
		ValorMaximo *float64 `json:"max_amount"`
		ValidoDe    *string  `json:"valid_from"`
		ValidoAte   *string  `json:"valid_until"`
		Activo      bool     `json:"active"`
	}
	data := []Row{}
	for rows.Next() {
		var d Row
		if rows.Scan(&d.ID, &d.Nome, &d.Descricao, &d.Tipo, &d.Valor, &d.ValorMinimo, &d.ValorMaximo, &d.ValidoDe, &d.ValidoAte, &d.Activo) == nil {
			data = append(data, d)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarDesconto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Nome        string   `json:"name"`
		Descricao   *string  `json:"description"`
		Tipo        string   `json:"type"`
		Valor       float64  `json:"value"`
		ValorMinimo *float64 `json:"min_amount"`
		ValorMaximo *float64 `json:"max_amount"`
		ValidoDe    *string  `json:"valid_from"`
		ValidoAte   *string  `json:"valid_until"`
		Activo      *bool    `json:"active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" || body.Valor <= 0 {
		jsonErr(w, "name e value são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Tipo != "percentual" && body.Tipo != "valor_fixo" {
		jsonErr(w, "type inválido: percentual ou valor_fixo", http.StatusBadRequest)
		return
	}
	activo := true
	if body.Activo != nil {
		activo = *body.Activo
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO pos.pos_discounts (tenant_id, nome, descricao, tipo, valor, valor_minimo, valor_maximo, valido_de, valido_ate, activo)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING id`,
		user.TenantID, body.Nome, body.Descricao, body.Tipo, body.Valor, body.ValorMinimo, body.ValorMaximo, body.ValidoDe, body.ValidoAte, activo).
		Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) AtualizarDesconto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome        *string  `json:"name"`
		Descricao   *string  `json:"description"`
		Tipo        *string  `json:"type"`
		Valor       *float64 `json:"value"`
		ValorMinimo *float64 `json:"min_amount"`
		ValorMaximo *float64 `json:"max_amount"`
		ValidoDe    *string  `json:"valid_from"`
		ValidoAte   *string  `json:"valid_until"`
		Activo      *bool    `json:"active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE pos.pos_discounts SET
		  nome = COALESCE($1, nome),
		  descricao = COALESCE($2, descricao),
		  tipo = COALESCE($3, tipo),
		  valor = COALESCE($4, valor),
		  valor_minimo = COALESCE($5, valor_minimo),
		  valor_maximo = COALESCE($6, valor_maximo),
		  valido_de = COALESCE($7, valido_de),
		  valido_ate = COALESCE($8, valido_ate),
		  activo = COALESCE($9, activo),
		  updated_at = NOW()
		WHERE id=$10 AND tenant_id=$11`,
		body.Nome, body.Descricao, body.Tipo, body.Valor, body.ValorMinimo, body.ValorMaximo,
		body.ValidoDe, body.ValidoAte, body.Activo, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Desconto não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverDesconto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `DELETE FROM pos.pos_discounts WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Desconto não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
