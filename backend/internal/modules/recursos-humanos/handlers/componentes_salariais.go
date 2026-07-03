package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

var tiposComponenteSalarialValidos = map[string]bool{
	"provento": true,
	"desconto": true,
}

var formasCalculoValidas = map[string]bool{
	"fixo":       true,
	"percentual": true,
}

type componenteSalarialRow struct {
	ID             int64    `json:"id"`
	Codigo         string   `json:"codigo"`
	Nome           string   `json:"nome"`
	Tipo           string   `json:"tipo"`
	FormaCalculo   string   `json:"forma_calculo"`
	ValorPadrao    *float64 `json:"valor_padrao"`
	Ativo          bool     `json:"ativo"`
	NumAtribuicoes int      `json:"num_atribuicoes"`
}

// ── Componentes Salariais: catálogo ─────────────────────────────────────────

func (h *Handler) ListarComponentesSalariais(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT c.id, c.codigo, c.nome, c.tipo, c.forma_calculo, c.valor_padrao, c.ativo,
		       (SELECT COUNT(*) FROM rh.funcionario_componentes_salariais fc WHERE fc.componente_id = c.id)
		  FROM rh.componentes_salariais c
		 WHERE c.tenant_id=$1
		 ORDER BY c.tipo, c.nome`, user.TenantID)
	defer rows.Close()
	data := []componenteSalarialRow{}
	for rows.Next() {
		var c componenteSalarialRow
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.Tipo, &c.FormaCalculo, &c.ValorPadrao, &c.Ativo, &c.NumAtribuicoes) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarComponenteSalarial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo       string   `json:"codigo"`
		Nome         string   `json:"nome"`
		Tipo         string   `json:"tipo"`
		FormaCalculo string   `json:"forma_calculo"`
		ValorPadrao  *float64 `json:"valor_padrao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if !tiposComponenteSalarialValidos[body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	if body.FormaCalculo == "" {
		body.FormaCalculo = "fixo"
	}
	if !formasCalculoValidas[body.FormaCalculo] {
		jsonErr(w, "forma_calculo inválida", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.componentes_salariais (tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Tipo, body.FormaCalculo, body.ValorPadrao).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um componente salarial com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarComponenteSalarial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo       *string  `json:"codigo"`
		Nome         *string  `json:"nome"`
		Tipo         *string  `json:"tipo"`
		FormaCalculo *string  `json:"forma_calculo"`
		ValorPadrao  *float64 `json:"valor_padrao"`
		Ativo        *bool    `json:"ativo"`
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
	if body.Tipo != nil && !tiposComponenteSalarialValidos[*body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	if body.FormaCalculo != nil && !formasCalculoValidas[*body.FormaCalculo] {
		jsonErr(w, "forma_calculo inválida", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.componentes_salariais SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), tipo=COALESCE($3,tipo),
		  forma_calculo=COALESCE($4,forma_calculo), valor_padrao=COALESCE($5,valor_padrao),
		  ativo=COALESCE($6,ativo), updated_at=NOW()
		WHERE id=$7 AND tenant_id=$8`,
		body.Codigo, body.Nome, body.Tipo, body.FormaCalculo, body.ValorPadrao, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um componente salarial com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Componente salarial não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverComponenteSalarial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var emUso bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.funcionario_componentes_salariais WHERE componente_id=$1 AND tenant_id=$2)`, id, user.TenantID).Scan(&emUso); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if emUso {
		jsonErr(w, "Não é possível eliminar um componente salarial atribuído a funcionários", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM rh.componentes_salariais WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Componente salarial não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
