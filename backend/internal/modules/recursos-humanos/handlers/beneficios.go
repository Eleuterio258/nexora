package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

type beneficioRow struct {
	ID             int64    `json:"id"`
	Codigo         string   `json:"codigo"`
	Nome           string   `json:"nome"`
	Descricao      *string  `json:"descricao"`
	ValorPadrao    *float64 `json:"valor_padrao"`
	Ativo          bool     `json:"ativo"`
	NumAtribuicoes int      `json:"num_atribuicoes"`
}

// ── Benefícios: catálogo ─────────────────────────────────────────────────────

func (h *Handler) ListarBeneficios(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT b.id, b.codigo, b.nome, b.descricao, b.valor_padrao, b.ativo,
		       (SELECT COUNT(*) FROM funcionario_beneficios fb WHERE fb.beneficio_id = b.id)
		  FROM beneficios b
		 WHERE b.tenant_id=$1
		 ORDER BY b.nome`, user.TenantID)
	defer rows.Close()
	data := []beneficioRow{}
	for rows.Next() {
		var b beneficioRow
		if rows.Scan(&b.ID, &b.Codigo, &b.Nome, &b.Descricao, &b.ValorPadrao, &b.Ativo, &b.NumAtribuicoes) == nil {
			data = append(data, b)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarBeneficio(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo      string   `json:"codigo"`
		Nome        string   `json:"nome"`
		Descricao   *string  `json:"descricao"`
		ValorPadrao *float64 `json:"valor_padrao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO beneficios (tenant_id, codigo, nome, descricao, valor_padrao)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao, body.ValorPadrao).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um benefício com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarBeneficio(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo      *string  `json:"codigo"`
		Nome        *string  `json:"nome"`
		Descricao   *string  `json:"descricao"`
		ValorPadrao *float64 `json:"valor_padrao"`
		Ativo       *bool    `json:"ativo"`
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
	tag, err := h.db.Exec(r.Context(), `
		UPDATE beneficios SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), descricao=COALESCE($3,descricao),
		  valor_padrao=COALESCE($4,valor_padrao), ativo=COALESCE($5,ativo), updated_at=NOW()
		WHERE id=$6 AND tenant_id=$7`,
		body.Codigo, body.Nome, body.Descricao, body.ValorPadrao, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um benefício com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Benefício não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverBeneficio(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var emUso bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM funcionario_beneficios WHERE beneficio_id=$1 AND tenant_id=$2)`, id, user.TenantID).Scan(&emUso); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if emUso {
		jsonErr(w, "Não é possível eliminar um benefício atribuído a funcionários", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM beneficios WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Benefício não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
