package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

var tiposMovimentoCaixaValidos = map[string]bool{
	"suprimento": true, "sangria": true, "deposito": true, "outro": true,
}

// RegistarMovimentoCaixa regista uma entrada/saída física de dinheiro numa
// sessão de caixa aberta (suprimento/sangria/depósito/outro). Só
// suprimento/sangria/depósito entram no cálculo automático do valor
// esperado do fecho (ver resumoMovimentosCaixa em pos.go) — "outro" é só
// para registo/auditoria.
func (h *Handler) RegistarMovimentoCaixa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	sessaoID := chi.URLParam(r, "id")

	var body struct {
		Tipo   string  `json:"tipo"`
		Valor  float64 `json:"valor"`
		Motivo *string `json:"motivo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || !tiposMovimentoCaixaValidos[body.Tipo] || body.Valor <= 0 {
		jsonErr(w, "tipo (suprimento/sangria/deposito/outro) e valor (>0) são obrigatórios", http.StatusBadRequest)
		return
	}

	var existeAberta bool
	if err := h.db.QueryRow(r.Context(), `
		SELECT true FROM pos_sessions WHERE id=$1 AND tenant_id=$2 AND status='aberta'`,
		sessaoID, user.TenantID).Scan(&existeAberta); err != nil {
		jsonErr(w, "Sessão de caixa não encontrada ou já fechada", http.StatusNotFound)
		return
	}

	var id int64
	if err := h.db.QueryRow(r.Context(), `
		INSERT INTO pos_cash_movements (tenant_id, pos_session_id, tipo, valor, motivo, created_by)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, sessaoID, body.Tipo, body.Valor, body.Motivo, user.ID,
	).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ListarMovimentosCaixa lista os movimentos de uma sessão (aberta ou já
// fechada — útil para o recibo de fecho revisitar o que aconteceu).
func (h *Handler) ListarMovimentosCaixa(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	sessaoID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT m.id, m.tipo, m.valor, m.motivo, m.created_by, COALESCE(u.nome,''), m.created_at
		  FROM pos_cash_movements m
		  JOIN pos_sessions s ON s.id = m.pos_session_id
		  LEFT JOIN auth.users u ON u.id = m.created_by
		 WHERE m.pos_session_id=$1 AND s.tenant_id=$2
		 ORDER BY m.created_at DESC`,
		sessaoID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID           int64     `json:"id"`
		Tipo         string    `json:"tipo"`
		Valor        float64   `json:"valor"`
		Motivo       *string   `json:"motivo"`
		CreatedBy    *int64    `json:"created_by"`
		OperadorNome string    `json:"operador_nome"`
		CreatedAt    time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.ID, &row.Tipo, &row.Valor, &row.Motivo, &row.CreatedBy, &row.OperadorNome, &row.CreatedAt) == nil {
			data = append(data, row)
		}
	}
	jsonOK(w, data, http.StatusOK)
}
