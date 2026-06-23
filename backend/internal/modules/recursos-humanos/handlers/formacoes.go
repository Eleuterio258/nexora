package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

var categoriasFormacaoValidas = map[string]bool{
	"tecnica":        true,
	"comportamental": true,
	"obrigatoria":    true,
	"outra":          true,
}

type formacaoRow struct {
	ID                int64    `json:"id"`
	Codigo            string   `json:"codigo"`
	Nome              string   `json:"nome"`
	Descricao         *string  `json:"descricao"`
	Categoria         string   `json:"categoria"`
	DuracaoHoras      *float64 `json:"duracao_horas"`
	EntidadeFormadora *string  `json:"entidade_formadora"`
	Ativo             bool     `json:"ativo"`
	NumParticipacoes  int      `json:"num_participacoes"`
}

// ── Formações: catálogo ──────────────────────────────────────────────────────

func (h *Handler) ListarFormacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT f.id, f.codigo, f.nome, f.descricao, f.categoria, f.duracao_horas, f.entidade_formadora, f.ativo,
		       (SELECT COUNT(*) FROM funcionario_formacoes ff WHERE ff.formacao_id = f.id)
		  FROM formacoes f
		 WHERE f.tenant_id=$1
		 ORDER BY f.nome`, user.TenantID)
	defer rows.Close()
	data := []formacaoRow{}
	for rows.Next() {
		var f formacaoRow
		if rows.Scan(&f.ID, &f.Codigo, &f.Nome, &f.Descricao, &f.Categoria, &f.DuracaoHoras, &f.EntidadeFormadora, &f.Ativo, &f.NumParticipacoes) == nil {
			data = append(data, f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarFormacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo            string   `json:"codigo"`
		Nome              string   `json:"nome"`
		Descricao         *string  `json:"descricao"`
		Categoria         string   `json:"categoria"`
		DuracaoHoras      *float64 `json:"duracao_horas"`
		EntidadeFormadora *string  `json:"entidade_formadora"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Categoria == "" {
		body.Categoria = "tecnica"
	}
	if !categoriasFormacaoValidas[body.Categoria] {
		jsonErr(w, "categoria inválida", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO formacoes (tenant_id, codigo, nome, descricao, categoria, duracao_horas, entidade_formadora)
		VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao, body.Categoria, body.DuracaoHoras, body.EntidadeFormadora).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe uma formação com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarFormacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo            *string  `json:"codigo"`
		Nome              *string  `json:"nome"`
		Descricao         *string  `json:"descricao"`
		Categoria         *string  `json:"categoria"`
		DuracaoHoras      *float64 `json:"duracao_horas"`
		EntidadeFormadora *string  `json:"entidade_formadora"`
		Ativo             *bool    `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.Codigo != nil && *body.Codigo == "" {
		jsonErr(w, "código não pode ser vazio", http.StatusBadRequest)
		return
	}
	if body.Nome != nil && *body.Nome == "" {
		jsonErr(w, "nome não pode ser vazio", http.StatusBadRequest)
		return
	}
	if body.Categoria != nil && !categoriasFormacaoValidas[*body.Categoria] {
		jsonErr(w, "categoria inválida", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE formacoes SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), descricao=COALESCE($3,descricao),
		  categoria=COALESCE($4,categoria), duracao_horas=COALESCE($5,duracao_horas),
		  entidade_formadora=COALESCE($6,entidade_formadora), ativo=COALESCE($7,ativo), updated_at=NOW()
		WHERE id=$8 AND tenant_id=$9`,
		body.Codigo, body.Nome, body.Descricao, body.Categoria, body.DuracaoHoras, body.EntidadeFormadora, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe uma formação com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Formação não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverFormacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var emUso bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM funcionario_formacoes WHERE formacao_id=$1 AND tenant_id=$2)`, id, user.TenantID).Scan(&emUso); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if emUso {
		jsonErr(w, "Não é possível eliminar uma formação com participações registadas", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM formacoes WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Formação não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
