package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	mw "nexora/internal/middleware"
)

// ── Tags NFC (assiduidade por cartão) ────────────────────────────────────────

type nfcTagRow struct {
	ID            int64     `json:"id"`
	FuncionarioID int64     `json:"funcionario_id"`
	TagUID        string    `json:"tag_uid"`
	Activo        bool      `json:"activo"`
	CreatedAt     time.Time `json:"created_at"`
}

// POST /api/rh/funcionarios/{id}/nfc-tags
func (h *Handler) CriarNFCTag(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	var body struct {
		TagUID string `json:"tag_uid"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.TagUID == "" {
		jsonErr(w, "tag_uid é obrigatório", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.nfc_tags (tenant_id, funcionario_id, tag_uid)
		VALUES ($1,$2,$3) RETURNING id`,
		user.TenantID, funcionarioID, body.TagUID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Tag NFC já registada", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// GET /api/rh/funcionarios/{id}/nfc-tags
func (h *Handler) ListarNFCTags(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	rows, _ := h.db.Query(r.Context(), `
		SELECT id, funcionario_id, tag_uid, activo, created_at
		  FROM rh.nfc_tags
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY created_at DESC`, funcionarioID, user.TenantID)
	if rows == nil {
		jsonOK(w, []nfcTagRow{}, http.StatusOK)
		return
	}
	defer rows.Close()

	data := []nfcTagRow{}
	for rows.Next() {
		var t nfcTagRow
		if rows.Scan(&t.ID, &t.FuncionarioID, &t.TagUID, &t.Activo, &t.CreatedAt) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// DELETE /api/rh/funcionarios/nfc-tags/{id}
func (h *Handler) RemoverNFCTag(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM rh.nfc_tags WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tag NFC não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/hardware/assiduidade/nfc/validar?tag_uid=
// Autenticado por API Key de device — o FaceClock identifica o funcionário
// a partir da tag lida pelo leitor NFC.
func (h *Handler) ValidarNFCDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}
	tagUID := r.URL.Query().Get("tag_uid")
	if tagUID == "" {
		jsonErr(w, "tag_uid é obrigatório", http.StatusBadRequest)
		return
	}

	var funcionarioUserID *int64
	var funcionarioNome string
	var activo bool
	err = h.db.QueryRow(r.Context(), `
		SELECT f.user_id, f.nome_completo, t.activo
		  FROM rh.nfc_tags t
		  JOIN rh.funcionarios f ON f.id = t.funcionario_id
		 WHERE t.tag_uid=$1 AND t.tenant_id=$2`,
		tagUID, tenantID).Scan(&funcionarioUserID, &funcionarioNome, &activo)
	if err != nil {
		jsonOK(w, map[string]any{"valid": false, "reason": "tag_not_found"}, http.StatusOK)
		return
	}
	if !activo || funcionarioUserID == nil {
		jsonOK(w, map[string]any{"valid": false, "reason": "tag_inactive"}, http.StatusOK)
		return
	}

	jsonOK(w, map[string]any{
		"valid":       true,
		"erp_user_id": *funcionarioUserID,
		"funcionario": funcionarioNome,
	}, http.StatusOK)
}
