package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── Adiantamentos ─────────────────────────────────────────────────────────────

type adiantamentoRow struct {
	ID              int64      `json:"id"`
	FuncionarioID   int64      `json:"funcionario_id"`
	ValorTotal      float64    `json:"valor_total"`
	NumPrestacoes   int        `json:"num_prestacoes"`
	PrestacaoValor  float64    `json:"prestacao_valor"`
	PrestacoesPagas int        `json:"prestacoes_pagas"`
	Estado          string     `json:"estado"`
	Descricao       *string    `json:"descricao"`
	DataInicio      time.Time  `json:"data_inicio"`
	CreatedAt       time.Time  `json:"created_at"`
}

func (h *Handler) ListarAdiantamentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT id, funcionario_id, valor_total, num_prestacoes, prestacao_valor,
		       prestacoes_pagas, estado, descricao, data_inicio, created_at
		  FROM rh.adiantamentos
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY created_at DESC`, funcID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []adiantamentoRow{}
	for rows.Next() {
		var a adiantamentoRow
		if rows.Scan(&a.ID, &a.FuncionarioID, &a.ValorTotal, &a.NumPrestacoes, &a.PrestacaoValor,
			&a.PrestacoesPagas, &a.Estado, &a.Descricao, &a.DataInicio, &a.CreatedAt) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarAdiantamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID := chi.URLParam(r, "id")

	var body struct {
		ValorTotal    float64 `json:"valor_total"`
		NumPrestacoes int     `json:"num_prestacoes"`
		Descricao     *string `json:"descricao"`
		DataInicio    *string `json:"data_inicio"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ValorTotal <= 0 || body.NumPrestacoes < 1 {
		jsonErr(w, "valor_total e num_prestacoes são obrigatórios", http.StatusBadRequest)
		return
	}
	prestacao := body.ValorTotal / float64(body.NumPrestacoes)

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.adiantamentos (tenant_id, funcionario_id, valor_total, num_prestacoes, prestacao_valor, descricao, data_inicio)
		VALUES ($1,$2,$3,$4,$5,$6,COALESCE($7::date,CURRENT_DATE)) RETURNING id`,
		user.TenantID, funcID, body.ValorTotal, body.NumPrestacoes, prestacao, body.Descricao, body.DataInicio,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "ok": true, "msg": "Adiantamento registado com sucesso."}, http.StatusCreated)
}

func (h *Handler) CancelarAdiantamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.adiantamentos SET estado='cancelado' WHERE id=$1 AND tenant_id=$2 AND estado='ativo'`,
		id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Adiantamento não encontrado ou já cancelado/quitado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Empréstimos ───────────────────────────────────────────────────────────────

type emprestimoRow struct {
	ID              int64      `json:"id"`
	FuncionarioID   int64      `json:"funcionario_id"`
	ValorTotal      float64    `json:"valor_total"`
	NumPrestacoes   int        `json:"num_prestacoes"`
	PrestacaoValor  float64    `json:"prestacao_valor"`
	PrestacoesPagas int        `json:"prestacoes_pagas"`
	TaxaJuros       float64    `json:"taxa_juros"`
	Estado          string     `json:"estado"`
	Descricao       *string    `json:"descricao"`
	DataInicio      time.Time  `json:"data_inicio"`
	CreatedAt       time.Time  `json:"created_at"`
}

func (h *Handler) ListarEmprestimos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT id, funcionario_id, valor_total, num_prestacoes, prestacao_valor,
		       prestacoes_pagas, taxa_juros, estado, descricao, data_inicio, created_at
		  FROM rh.emprestimos
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY created_at DESC`, funcID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []emprestimoRow{}
	for rows.Next() {
		var e emprestimoRow
		if rows.Scan(&e.ID, &e.FuncionarioID, &e.ValorTotal, &e.NumPrestacoes, &e.PrestacaoValor,
			&e.PrestacoesPagas, &e.TaxaJuros, &e.Estado, &e.Descricao, &e.DataInicio, &e.CreatedAt) == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarEmprestimo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID := chi.URLParam(r, "id")

	var body struct {
		ValorTotal    float64  `json:"valor_total"`
		NumPrestacoes int      `json:"num_prestacoes"`
		TaxaJuros     *float64 `json:"taxa_juros"`
		Descricao     *string  `json:"descricao"`
		DataInicio    *string  `json:"data_inicio"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ValorTotal <= 0 || body.NumPrestacoes < 1 {
		jsonErr(w, "valor_total e num_prestacoes são obrigatórios", http.StatusBadRequest)
		return
	}
	taxa := 0.0
	if body.TaxaJuros != nil {
		taxa = *body.TaxaJuros
	}
	prestacao := (body.ValorTotal * (1 + taxa)) / float64(body.NumPrestacoes)

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.emprestimos (tenant_id, funcionario_id, valor_total, num_prestacoes, prestacao_valor, taxa_juros, descricao, data_inicio)
		VALUES ($1,$2,$3,$4,$5,$6,$7,COALESCE($8::date,CURRENT_DATE)) RETURNING id`,
		user.TenantID, funcID, body.ValorTotal, body.NumPrestacoes, prestacao, taxa, body.Descricao, body.DataInicio,
	).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "ok": true, "msg": "Empréstimo registado com sucesso."}, http.StatusCreated)
}

func (h *Handler) CancelarEmprestimo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.emprestimos SET estado='cancelado' WHERE id=$1 AND tenant_id=$2 AND estado='ativo'`,
		id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Empréstimo não encontrado ou já cancelado/quitado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
