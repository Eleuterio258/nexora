package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

type taxGroupRow struct {
	ID     int64  `json:"id"`
	Codigo string `json:"codigo"`
	Nome   string `json:"nome"`
	Ativo  bool   `json:"ativo"`
}

func (h *Handler) ListarGruposImposto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("ativo"); v != "" {
		args = append(args, v == "true")
		where += " AND ativo=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), `SELECT id, codigo, nome, ativo FROM impostos.tax_groups WHERE `+where+` ORDER BY codigo`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []taxGroupRow{}
	for rows.Next() {
		var g taxGroupRow
		if rows.Scan(&g.ID, &g.Codigo, &g.Nome, &g.Ativo) == nil {
			data = append(data, g)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarGrupoImposto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO impostos.tax_groups (tenant_id,codigo,nome)
		VALUES ($1,$2,$3) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarGrupoImposto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo *string `json:"codigo"`
		Nome   *string `json:"nome"`
		Ativo  *bool   `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE impostos.tax_groups SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), ativo=COALESCE($3,ativo)
		WHERE id=$4 AND tenant_id=$5`,
		body.Codigo, body.Nome, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Grupo de imposto não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
