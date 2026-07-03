package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// CampoCustomRow representa um campo customizável do formulário de candidatura.
type CampoCustomRow struct {
	ID          int64     `json:"id"`
	Codigo      string    `json:"codigo"`
	Label       string    `json:"label"`
	Tipo        string    `json:"tipo"`
	Opcoes      []string  `json:"opcoes"`
	Obrigatorio bool      `json:"obrigatorio"`
	Ordem       int       `json:"ordem"`
	Ativo       bool      `json:"ativo"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

func scanCampoCustom(rows any) []CampoCustomRow {
	// Implementação feita inline nas queries
	return nil
}

// ListarCamposCustom retorna os campos customizáveis do tenant (admin).
func (h *Handler) ListarCamposCustom(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	rows, err := h.db.Query(r.Context(), `
		SELECT id, codigo, label, tipo, opcoes, obrigatorio, ordem, ativo, created_at, updated_at
		  FROM candidatura_campos_custom
		 WHERE tenant_id=$1
		 ORDER BY ordem, id`, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []CampoCustomRow{}
	for rows.Next() {
		var c CampoCustomRow
		var opcoesJSON []byte
		if err := rows.Scan(&c.ID, &c.Codigo, &c.Label, &c.Tipo, &opcoesJSON, &c.Obrigatorio, &c.Ordem, &c.Ativo, &c.CreatedAt, &c.UpdatedAt); err != nil {
			continue
		}
		json.Unmarshal(opcoesJSON, &c.Opcoes)
		data = append(data, c)
	}
	jsonOK(w, data, http.StatusOK)
}

// CriarCampoCustom cria um novo campo customizável.
func (h *Handler) CriarCampoCustom(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		Codigo      string   `json:"codigo"`
		Label       string   `json:"label"`
		Tipo        string   `json:"tipo"`
		Opcoes      []string `json:"opcoes"`
		Obrigatorio bool     `json:"obrigatorio"`
		Ordem       int      `json:"ordem"`
		Ativo       *bool    `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	body.Codigo = strings.TrimSpace(body.Codigo)
	body.Label = strings.TrimSpace(body.Label)
	body.Tipo = strings.TrimSpace(body.Tipo)

	if body.Codigo == "" || body.Label == "" || body.Tipo == "" {
		jsonErr(w, "codigo, label e tipo são obrigatórios", http.StatusBadRequest)
		return
	}
	validTypes := map[string]bool{"texto": true, "textarea": true, "numero": true, "data": true, "select": true, "multiselect": true, "checkbox": true, "ficheiro": true}
	if !validTypes[body.Tipo] {
		jsonErr(w, "tipo inválido", http.StatusBadRequest)
		return
	}
	if body.Opcoes == nil {
		body.Opcoes = []string{}
	}

	opcoesJSON, _ := json.Marshal(body.Opcoes)
	var id int64
	ativo := true
	if body.Ativo != nil {
		ativo = *body.Ativo
	}
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO candidatura_campos_custom (tenant_id, codigo, label, tipo, opcoes, obrigatorio, ordem, ativo)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		u.TenantID, body.Codigo, body.Label, body.Tipo, opcoesJSON, body.Obrigatorio, body.Ordem, ativo).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um campo com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao criar campo", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ActualizarCampoCustom atualiza um campo existente.
func (h *Handler) ActualizarCampoCustom(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo      *string  `json:"codigo"`
		Label       *string  `json:"label"`
		Tipo        *string  `json:"tipo"`
		Opcoes      *[]string `json:"opcoes"`
		Obrigatorio *bool    `json:"obrigatorio"`
		Ordem       *int     `json:"ordem"`
		Ativo       *bool    `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	updates := []string{}
	args := []any{}
	argIdx := 1

	if body.Codigo != nil {
		updates = append(updates, "codigo=$"+strconv.Itoa(argIdx))
		args = append(args, strings.TrimSpace(*body.Codigo))
		argIdx++
	}
	if body.Label != nil {
		updates = append(updates, "label=$"+strconv.Itoa(argIdx))
		args = append(args, strings.TrimSpace(*body.Label))
		argIdx++
	}
	if body.Tipo != nil {
		updates = append(updates, "tipo=$"+strconv.Itoa(argIdx))
		args = append(args, strings.TrimSpace(*body.Tipo))
		argIdx++
	}
	if body.Opcoes != nil {
		updates = append(updates, "opcoes=$"+strconv.Itoa(argIdx))
		args = append(args, mustJSON(*body.Opcoes))
		argIdx++
	}
	if body.Obrigatorio != nil {
		updates = append(updates, "obrigatorio=$"+strconv.Itoa(argIdx))
		args = append(args, *body.Obrigatorio)
		argIdx++
	}
	if body.Ordem != nil {
		updates = append(updates, "ordem=$"+strconv.Itoa(argIdx))
		args = append(args, *body.Ordem)
		argIdx++
	}
	if body.Ativo != nil {
		updates = append(updates, "ativo=$"+strconv.Itoa(argIdx))
		args = append(args, *body.Ativo)
		argIdx++
	}

	if len(updates) == 0 {
		jsonErr(w, "Nenhum campo para atualizar", http.StatusBadRequest)
		return
	}

	updates = append(updates, "updated_at=NOW()")
	args = append(args, id, u.TenantID)

	query := "UPDATE candidatura_campos_custom SET " + strings.Join(updates, ", ") + " WHERE id=$" + strconv.Itoa(argIdx) + " AND tenant_id=$" + strconv.Itoa(argIdx+1)
	tag, err := h.db.Exec(r.Context(), query, args...)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Campo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// EliminarCampoCustom remove um campo customizável.
func (h *Handler) EliminarCampoCustom(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM candidatura_campos_custom
		 WHERE id=$1 AND tenant_id=$2`, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Campo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

func mustJSON(v any) json.RawMessage {
	b, _ := json.Marshal(v)
	return json.RawMessage(b)
}
