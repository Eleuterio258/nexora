package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Benefícios atribuídos a um funcionário ──────────────────────────────────

func (h *Handler) ListarBeneficiosFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT b.id, b.codigo, b.nome, fb.valor, fb.data_inicio, fb.data_fim, fb.observacoes
		  FROM rh.funcionario_beneficios fb
		  JOIN rh.beneficios b ON b.id = fb.beneficio_id
		 WHERE fb.funcionario_id=$1 AND fb.tenant_id=$2
		 ORDER BY b.nome`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		BeneficioID int64      `json:"beneficio_id"`
		Codigo      string     `json:"codigo"`
		Nome        string     `json:"nome"`
		Valor       *float64   `json:"valor"`
		DataInicio  time.Time  `json:"data_inicio"`
		DataFim     *time.Time `json:"data_fim"`
		Observacoes *string    `json:"observacoes"`
	}
	data := []Row{}
	for rows.Next() {
		var b Row
		if rows.Scan(&b.BeneficioID, &b.Codigo, &b.Nome, &b.Valor, &b.DataInicio, &b.DataFim, &b.Observacoes) == nil {
			data = append(data, b)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarBeneficioFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		BeneficioID int64    `json:"beneficio_id"`
		Valor       *float64 `json:"valor"`
		DataInicio  *string  `json:"data_inicio"`
		DataFim     *string  `json:"data_fim"`
		Observacoes *string  `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.BeneficioID == 0 {
		jsonErr(w, "beneficio_id é obrigatório", http.StatusBadRequest)
		return
	}

	var existe bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.beneficios WHERE id=$1 AND tenant_id=$2 AND ativo)`, body.BeneficioID, user.TenantID).Scan(&existe); err != nil || !existe {
		jsonErr(w, "Benefício inválido", http.StatusBadRequest)
		return
	}

	dataInicio := time.Now().Format("2006-01-02")
	if body.DataInicio != nil && *body.DataInicio != "" {
		if _, err := time.Parse("2006-01-02", *body.DataInicio); err != nil {
			jsonErr(w, "data_inicio inválida", http.StatusBadRequest)
			return
		}
		dataInicio = *body.DataInicio
	}
	if body.DataFim != nil && *body.DataFim != "" {
		if _, err := time.Parse("2006-01-02", *body.DataFim); err != nil {
			jsonErr(w, "data_fim inválida", http.StatusBadRequest)
			return
		}
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.funcionario_beneficios (tenant_id, funcionario_id, beneficio_id, valor, data_inicio, data_fim, observacoes)
		VALUES ($1,$2,$3,$4,$5::date,$6::date,$7)
		ON CONFLICT (funcionario_id, beneficio_id) DO UPDATE SET
		  valor=EXCLUDED.valor, data_inicio=EXCLUDED.data_inicio, data_fim=EXCLUDED.data_fim, observacoes=EXCLUDED.observacoes
		RETURNING id`,
		user.TenantID, funcionarioID, body.BeneficioID, body.Valor, dataInicio, body.DataFim, body.Observacoes).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverBeneficioFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")
	beneficioID := chi.URLParam(r, "beneficioId")

	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM rh.funcionario_beneficios
		 WHERE funcionario_id=$1 AND beneficio_id=$2 AND tenant_id=$3`,
		funcionarioID, beneficioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Benefício não encontrado para este funcionário", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
