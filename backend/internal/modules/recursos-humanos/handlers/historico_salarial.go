package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Histórico Salarial ──────────────────────────────────────────────────────

func (h *Handler) ListarHistoricoSalarial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT id, salario_anterior, salario_novo, data_efectiva, motivo, created_at
		  FROM historico_salarial
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY data_efectiva DESC, id DESC`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID              int64     `json:"id"`
		SalarioAnterior *float64  `json:"salario_anterior"`
		SalarioNovo     *float64  `json:"salario_novo"`
		DataEfectiva    time.Time `json:"data_efectiva"`
		Motivo          *string   `json:"motivo"`
		CreatedAt       time.Time `json:"created_at"`
	}
	podeVerSalarios := h.PodeVerSalarios(r)
	data := []Row{}
	for rows.Next() {
		var hr Row
		var salarioNovo float64
		if rows.Scan(&hr.ID, &hr.SalarioAnterior, &salarioNovo, &hr.DataEfectiva, &hr.Motivo, &hr.CreatedAt) == nil {
			if podeVerSalarios {
				hr.SalarioNovo = &salarioNovo
			} else {
				hr.SalarioAnterior = nil
			}
			data = append(data, hr)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarAlteracaoSalarial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		SalarioNovo  float64 `json:"salario_novo"`
		DataEfectiva string  `json:"data_efectiva"`
		Motivo       *string `json:"motivo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.SalarioNovo <= 0 || body.DataEfectiva == "" {
		jsonErr(w, "salario_novo e data_efectiva são obrigatórios", http.StatusBadRequest)
		return
	}
	if _, err := time.Parse("2006-01-02", body.DataEfectiva); err != nil {
		jsonErr(w, "data_efectiva inválida", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var salarioAnterior *float64
	if err := tx.QueryRow(r.Context(), `
		SELECT salario_base FROM funcionarios WHERE id=$1 AND tenant_id=$2`,
		funcionarioID, user.TenantID).Scan(&salarioAnterior); err != nil {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	if _, err := tx.Exec(r.Context(), `
		UPDATE funcionarios SET salario_base=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3`,
		body.SalarioNovo, funcionarioID, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO historico_salarial (tenant_id, funcionario_id, salario_anterior, salario_novo, data_efectiva, motivo)
		VALUES ($1,$2,$3,$4,$5::date,$6) RETURNING id`,
		user.TenantID, funcionarioID, salarioAnterior, body.SalarioNovo, body.DataEfectiva, body.Motivo).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
