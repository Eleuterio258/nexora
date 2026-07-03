package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

type VagaCampo struct {
	ID          int64    `json:"id"`
	VagaID      int64    `json:"vaga_id"`
	Codigo      string   `json:"codigo"`
	Label       string   `json:"label"`
	Tipo        string   `json:"tipo"`
	Opcoes      []string `json:"opcoes"`
	Obrigatorio bool     `json:"obrigatorio"`
	Ordem       int      `json:"ordem"`
	Ativo       bool     `json:"ativo"`
}

var tiposVagaCampo = map[string]bool{
	"texto": true, "textarea": true, "numero": true, "data": true,
	"select": true, "multiselect": true, "checkbox": true, "ficheiro": true,
}

// ListarVagaCampos lista os campos do formulário de uma vaga específica.
func (h *Handler) ListarVagaCampos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	vagaID := chi.URLParam(r, "vagaID")

	rows, err := h.db.Query(r.Context(), `
		SELECT vc.id, vc.vaga_id, vc.codigo, vc.label, vc.tipo, vc.opcoes, vc.obrigatorio, vc.ordem, vc.ativo
		  FROM vaga_campos vc
		  JOIN vagas v ON v.id = vc.vaga_id
		 WHERE vc.vaga_id = $1 AND v.tenant_id = $2
		 ORDER BY vc.ordem, vc.id`, vagaID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []VagaCampo{}
	for rows.Next() {
		var c VagaCampo
		var opcoesJSON []byte
		if err := rows.Scan(&c.ID, &c.VagaID, &c.Codigo, &c.Label, &c.Tipo, &opcoesJSON, &c.Obrigatorio, &c.Ordem, &c.Ativo); err != nil {
			continue
		}
		json.Unmarshal(opcoesJSON, &c.Opcoes)
		data = append(data, c)
	}
	jsonOK(w, data, http.StatusOK)
}

// CriarVagaCampo cria um campo no formulário de uma vaga.
func (h *Handler) CriarVagaCampo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	vagaID, err := strconv.ParseInt(chi.URLParam(r, "vagaID"), 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido.", http.StatusBadRequest)
		return
	}

	var body struct {
		Codigo      string   `json:"codigo"`
		Label       string   `json:"label"`
		Tipo        string   `json:"tipo"`
		Opcoes      []string `json:"opcoes"`
		Obrigatorio bool     `json:"obrigatorio"`
		Ordem       int      `json:"ordem"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	body.Codigo = strings.TrimSpace(body.Codigo)
	body.Label = strings.TrimSpace(body.Label)
	body.Tipo = strings.TrimSpace(body.Tipo)

	if body.Codigo == "" || body.Label == "" {
		jsonErr(w, "Código e label são obrigatórios.", http.StatusUnprocessableEntity)
		return
	}
	if !tiposVagaCampo[body.Tipo] {
		jsonErr(w, "Tipo de campo inválido.", http.StatusUnprocessableEntity)
		return
	}

	// Verificar que a vaga pertence ao tenant
	var exists bool
	if err := h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM vagas WHERE id=$1 AND tenant_id=$2)`, vagaID, user.TenantID,
	).Scan(&exists); err != nil || !exists {
		jsonErr(w, "Vaga não encontrada.", http.StatusNotFound)
		return
	}

	opcoes := body.Opcoes
	if opcoes == nil {
		opcoes = []string{}
	}
	opcoesJSON, _ := json.Marshal(opcoes)

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO vaga_campos (vaga_id, tenant_id, codigo, label, tipo, opcoes, obrigatorio, ordem, ativo)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,TRUE)
		RETURNING id`,
		vagaID, user.TenantID, body.Codigo, body.Label, body.Tipo,
		opcoesJSON, body.Obrigatorio, body.Ordem,
	).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um campo com esse código nesta vaga.", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao guardar campo.", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// ActualizarVagaCampo actualiza um campo do formulário de uma vaga.
func (h *Handler) ActualizarVagaCampo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	campoID := chi.URLParam(r, "campoID")

	var body struct {
		Label       *string  `json:"label"`
		Tipo        *string  `json:"tipo"`
		Opcoes      []string `json:"opcoes"`
		Obrigatorio *bool    `json:"obrigatorio"`
		Ordem       *int     `json:"ordem"`
		Ativo       *bool    `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido.", http.StatusBadRequest)
		return
	}
	if body.Tipo != nil && !tiposVagaCampo[*body.Tipo] {
		jsonErr(w, "Tipo de campo inválido.", http.StatusUnprocessableEntity)
		return
	}

	sets := []string{"updated_at=NOW()"}
	args := []any{}

	if body.Label != nil {
		args = append(args, strings.TrimSpace(*body.Label))
		sets = append(sets, "label=$"+strconv.Itoa(len(args)))
	}
	if body.Tipo != nil {
		args = append(args, *body.Tipo)
		sets = append(sets, "tipo=$"+strconv.Itoa(len(args)))
	}
	if body.Opcoes != nil {
		opcoesJSON, _ := json.Marshal(body.Opcoes)
		args = append(args, opcoesJSON)
		sets = append(sets, "opcoes=$"+strconv.Itoa(len(args)))
	}
	if body.Obrigatorio != nil {
		args = append(args, *body.Obrigatorio)
		sets = append(sets, "obrigatorio=$"+strconv.Itoa(len(args)))
	}
	if body.Ordem != nil {
		args = append(args, *body.Ordem)
		sets = append(sets, "ordem=$"+strconv.Itoa(len(args)))
	}
	if body.Ativo != nil {
		args = append(args, *body.Ativo)
		sets = append(sets, "ativo=$"+strconv.Itoa(len(args)))
	}

	args = append(args, campoID, user.TenantID)
	idxCampo := strconv.Itoa(len(args) - 1)
	idxTenant := strconv.Itoa(len(args))

	tag, err := h.db.Exec(r.Context(), `
		UPDATE vaga_campos vc SET `+strings.Join(sets, ",")+`
		 WHERE vc.id=$`+idxCampo+`
		   AND EXISTS (SELECT 1 FROM vagas v WHERE v.id=vc.vaga_id AND v.tenant_id=$`+idxTenant+`)`,
		args...)
	if err != nil {
		jsonErr(w, "Erro ao actualizar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Campo não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// EliminarVagaCampo elimina um campo do formulário de uma vaga.
func (h *Handler) EliminarVagaCampo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	campoID := chi.URLParam(r, "campoID")

	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM vaga_campos vc
		 WHERE vc.id=$1
		   AND EXISTS (SELECT 1 FROM vagas v WHERE v.id=vc.vaga_id AND v.tenant_id=$2)`,
		campoID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao eliminar.", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Campo não encontrado.", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
