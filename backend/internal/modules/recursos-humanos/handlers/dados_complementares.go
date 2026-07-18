package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/pessoas"
)

var tiposDocumentoValidos = map[string]bool{
	"bi": true, "passaporte": true, "carta_conducao": true, "cartao_eleitor": true, "certidao_nascimento": true, "outro": true,
}

func (h *Handler) funcionarioPertenceTenant(ctx context.Context, funcionarioID int64, tenantID int64) bool {
	var existe bool
	h.db.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM rh.funcionarios WHERE id=$1 AND tenant_id=$2)`, funcionarioID, tenantID).Scan(&existe)
	return existe
}

// ── Contactos de Emergência ──────────────────────────────────────────────────

func (h *Handler) CriarContactoEmergencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FuncionarioID int64   `json:"funcionario_id"`
		Nome          string  `json:"nome"`
		Parentesco    *string `json:"parentesco"`
		Telefone      string  `json:"telefone"`
		Email         *string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FuncionarioID == 0 || body.Nome == "" || body.Telefone == "" {
		jsonErr(w, "funcionario_id, nome e telefone são obrigatórios", http.StatusBadRequest)
		return
	}
	if !h.funcionarioPertenceTenant(r.Context(), body.FuncionarioID, user.TenantID) {
		jsonErr(w, "Funcionário inválido", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.contactos_emergencia (tenant_id, funcionario_id, nome, parentesco, telefone, email)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.FuncionarioID, body.Nome, body.Parentesco, body.Telefone, body.Email).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Ligar o contacto a uma pessoa e registar a relação com o funcionário
	// (ver docs/analise-modelo-pessoa-multi-tenant.md secção 9).
	var funcionarioPessoaID *int64
	if h.db.QueryRow(r.Context(), `SELECT pessoa_id FROM rh.funcionarios WHERE id=$1`, body.FuncionarioID).Scan(&funcionarioPessoaID) == nil && funcionarioPessoaID != nil {
		if contactoPessoaID, err := pessoas.EnsurePessoa(r.Context(), h.db, body.Nome); err == nil {
			h.db.Exec(r.Context(), `UPDATE rh.contactos_emergencia SET pessoa_id = $1 WHERE id = $2`, contactoPessoaID, id)
			parentesco := ""
			if body.Parentesco != nil {
				parentesco = *body.Parentesco
			}
			_ = pessoas.LinkPessoaRelacao(r.Context(), h.db, user.TenantID, contactoPessoaID, *funcionarioPessoaID, parentesco, false)
		}
	}

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverContactoEmergencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `DELETE FROM rh.contactos_emergencia WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Contacto de emergência não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Documentos do Funcionário ─────────────────────────────────────────────────

func (h *Handler) CriarDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FuncionarioID int64   `json:"funcionario_id"`
		Tipo          string  `json:"tipo"`
		Numero        *string `json:"numero"`
		DataEmissao   *string `json:"data_emissao"`
		DataValidade  *string `json:"data_validade"`
		FicheiroURL   *string `json:"ficheiro_url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FuncionarioID == 0 || !tiposDocumentoValidos[body.Tipo] {
		jsonErr(w, "funcionario_id e tipo são obrigatórios", http.StatusBadRequest)
		return
	}
	if !h.funcionarioPertenceTenant(r.Context(), body.FuncionarioID, user.TenantID) {
		jsonErr(w, "Funcionário inválido", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.documentos_funcionario (tenant_id, funcionario_id, tipo, numero, data_emissao, data_validade, ficheiro_url)
		VALUES ($1,$2,$3,$4,$5::date,$6::date,$7) RETURNING id`,
		user.TenantID, body.FuncionarioID, body.Tipo, body.Numero, body.DataEmissao, body.DataValidade, body.FicheiroURL).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var ficheiroURL *string
	err := h.db.QueryRow(r.Context(), `
		DELETE FROM rh.documentos_funcionario WHERE id=$1 AND tenant_id=$2 RETURNING ficheiro_url`, id, user.TenantID).Scan(&ficheiroURL)
	if err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ficheiro_url": ficheiroURL}, http.StatusOK)
}
