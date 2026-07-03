package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Componentes Salariais atribuídos a um funcionário ───────────────────────

func (h *Handler) ListarComponentesFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), `
		SELECT c.id, c.codigo, c.nome, c.tipo, c.forma_calculo, fc.valor
		  FROM rh.funcionario_componentes_salariais fc
		  JOIN rh.componentes_salariais c ON c.id = fc.componente_id
		 WHERE fc.funcionario_id=$1 AND fc.tenant_id=$2
		 ORDER BY c.tipo, c.nome`, funcionarioID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ComponenteID int64    `json:"componente_id"`
		Codigo       string   `json:"codigo"`
		Nome         string   `json:"nome"`
		Tipo         string   `json:"tipo"`
		FormaCalculo string   `json:"forma_calculo"`
		Valor        *float64 `json:"valor"`
	}
	podeVerSalarios := h.PodeVerSalarios(r)
	data := []Row{}
	for rows.Next() {
		var c Row
		var valor float64
		if rows.Scan(&c.ComponenteID, &c.Codigo, &c.Nome, &c.Tipo, &c.FormaCalculo, &valor) == nil {
			if podeVerSalarios {
				c.Valor = &valor
			}
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) AdicionarComponenteFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		ComponenteID int64   `json:"componente_id"`
		Valor        float64 `json:"valor"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ComponenteID == 0 {
		jsonErr(w, "componente_id é obrigatório", http.StatusBadRequest)
		return
	}

	var existe bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.componentes_salariais WHERE id=$1 AND tenant_id=$2 AND ativo)`, body.ComponenteID, user.TenantID).Scan(&existe); err != nil || !existe {
		jsonErr(w, "Componente salarial inválido", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.funcionario_componentes_salariais (tenant_id, funcionario_id, componente_id, valor)
		VALUES ($1,$2,$3,$4)
		ON CONFLICT (funcionario_id, componente_id) DO UPDATE SET valor=EXCLUDED.valor
		RETURNING id`,
		user.TenantID, funcionarioID, body.ComponenteID, body.Valor).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverComponenteFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")
	componenteID := chi.URLParam(r, "componenteId")

	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM rh.funcionario_componentes_salariais
		 WHERE funcionario_id=$1 AND componente_id=$2 AND tenant_id=$3`,
		funcionarioID, componenteID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Componente não encontrado para este funcionário", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
