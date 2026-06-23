package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

var tiposDiarioValidos = map[string]bool{
	"geral":      true,
	"vendas":     true,
	"compras":    true,
	"tesouraria": true,
	"folha":      true,
	"ajuste":     true,
}

type journalRow struct {
	ID     int64  `json:"id"`
	Codigo string `json:"codigo"`
	Nome   string `json:"nome"`
	Tipo   string `json:"tipo"`
	Ativo  bool   `json:"ativo"`
}

func (h *Handler) ListarDiarios(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, tipo, ativo
		  FROM contabilidade.accounting_journals
		 WHERE tenant_id=$1
		 ORDER BY codigo`, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []journalRow{}
	for rows.Next() {
		var j journalRow
		if rows.Scan(&j.ID, &j.Codigo, &j.Nome, &j.Tipo, &j.Ativo) == nil {
			data = append(data, j)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarDiario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
		Tipo   string `json:"tipo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if !tiposDiarioValidos[body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO contabilidade.accounting_journals (tenant_id,codigo,nome,tipo)
		VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Tipo).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código de diário já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarDiario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Nome  *string `json:"nome"`
		Tipo  *string `json:"tipo"`
		Ativo *bool   `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if body.Tipo != nil && !tiposDiarioValidos[*body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.accounting_journals SET
		  nome=COALESCE($1,nome), tipo=COALESCE($2,tipo), ativo=COALESCE($3,ativo)
		WHERE id=$4 AND tenant_id=$5`,
		body.Nome, body.Tipo, body.Ativo, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Diário não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
