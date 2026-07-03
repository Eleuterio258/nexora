package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

var estadosFormacaoFuncionarioValidos = map[string]bool{
	"planeada":  true,
	"em_curso":  true,
	"concluida": true,
	"cancelada": true,
}

// ── Formações: participação de um funcionário ───────────────────────────────

func (h *Handler) ListarFormacoesFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT ff.id, f.id, f.codigo, f.nome, f.categoria, ff.data_inicio, ff.data_fim, ff.estado, ff.nota, ff.certificado_url, ff.observacoes
		  FROM rh.funcionario_formacoes ff
		  JOIN rh.formacoes f ON f.id = ff.formacao_id
		 WHERE ff.funcionario_id=$1 AND ff.tenant_id=$2
		 ORDER BY ff.data_inicio DESC`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID             int64      `json:"id"`
		FormacaoID     int64      `json:"formacao_id"`
		Codigo         string     `json:"codigo"`
		Nome           string     `json:"nome"`
		Categoria      string     `json:"categoria"`
		DataInicio     time.Time  `json:"data_inicio"`
		DataFim        *time.Time `json:"data_fim"`
		Estado         string     `json:"estado"`
		Nota           *float64   `json:"nota"`
		CertificadoURL *string    `json:"certificado_url"`
		Observacoes    *string    `json:"observacoes"`
	}
	data := []Row{}
	for rows.Next() {
		var f Row
		if rows.Scan(&f.ID, &f.FormacaoID, &f.Codigo, &f.Nome, &f.Categoria, &f.DataInicio, &f.DataFim, &f.Estado, &f.Nota, &f.CertificadoURL, &f.Observacoes) == nil {
			data = append(data, f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarFormacaoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		FormacaoID  int64   `json:"formacao_id"`
		DataInicio  string  `json:"data_inicio"`
		DataFim     *string `json:"data_fim"`
		Observacoes *string `json:"observacoes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FormacaoID == 0 || body.DataInicio == "" {
		jsonErr(w, "formacao_id e data_inicio são obrigatórios", http.StatusBadRequest)
		return
	}
	if _, err := time.Parse("2006-01-02", body.DataInicio); err != nil {
		jsonErr(w, "data_inicio inválida", http.StatusBadRequest)
		return
	}
	if body.DataFim != nil && *body.DataFim != "" {
		if _, err := time.Parse("2006-01-02", *body.DataFim); err != nil {
			jsonErr(w, "data_fim inválida", http.StatusBadRequest)
			return
		}
	}

	var existe bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.formacoes WHERE id=$1 AND tenant_id=$2 AND ativo)`, body.FormacaoID, user.TenantID).Scan(&existe); err != nil || !existe {
		jsonErr(w, "Formação inválida", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.funcionario_formacoes (tenant_id, funcionario_id, formacao_id, data_inicio, data_fim, observacoes)
		VALUES ($1,$2,$3,$4::date,$5::date,$6) RETURNING id`,
		user.TenantID, funcionarioID, body.FormacaoID, body.DataInicio, body.DataFim, body.Observacoes).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarFormacaoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")
	registoID := chi.URLParam(r, "registoId")

	var body struct {
		DataFim        *string  `json:"data_fim"`
		Estado         *string  `json:"estado"`
		Nota           *float64 `json:"nota"`
		CertificadoURL *string  `json:"certificado_url"`
		Observacoes    *string  `json:"observacoes"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.Estado != nil && !estadosFormacaoFuncionarioValidos[*body.Estado] {
		jsonErr(w, "estado inválido", http.StatusBadRequest)
		return
	}
	if body.DataFim != nil && *body.DataFim != "" {
		if _, err := time.Parse("2006-01-02", *body.DataFim); err != nil {
			jsonErr(w, "data_fim inválida", http.StatusBadRequest)
			return
		}
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.funcionario_formacoes SET
		  data_fim=COALESCE($1::date,data_fim), estado=COALESCE($2,estado), nota=COALESCE($3,nota),
		  certificado_url=COALESCE($4,certificado_url), observacoes=COALESCE($5,observacoes)
		WHERE id=$6 AND funcionario_id=$7 AND tenant_id=$8`,
		body.DataFim, body.Estado, body.Nota, body.CertificadoURL, body.Observacoes, registoID, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Registo de formação não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverFormacaoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")
	registoID := chi.URLParam(r, "registoId")

	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM rh.funcionario_formacoes
		 WHERE id=$1 AND funcionario_id=$2 AND tenant_id=$3`,
		registoID, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Registo de formação não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
