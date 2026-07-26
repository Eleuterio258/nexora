package handlers

import (
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// FingerprintEnrollRequest representa o body para registo de um template.
type FingerprintEnrollRequest struct {
	UserID           string  `json:"user_id"`
	ERPFuncionarioID *string `json:"erp_funcionario_id"`
	FingerType       string  `json:"finger_type"`
	TemplateBase64   string  `json:"template_base64"`
}

// FingerprintEnrollResponse representa a resposta de um registo bem-sucedido.
type FingerprintEnrollResponse struct {
	Success    bool   `json:"success"`
	TemplateID int64  `json:"template_id"`
	UserID     string `json:"user_id"`
	Message    string `json:"message"`
}

// FingerprintIdentifyRequest representa o body para identificação 1:N.
type FingerprintIdentifyRequest struct {
	TemplateBase64 string `json:"template_base64"`
}

// FingerprintIdentifyResponse representa a resposta de identificação.
type FingerprintIdentifyResponse struct {
	Success bool   `json:"success"`
	UserID  string `json:"user_id,omitempty"`
	Message string `json:"message"`
}

// EnrollFingerprint regista ou actualiza um template de impressão digital.
func (h *Handler) EnrollFingerprint(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body FingerprintEnrollRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "body JSON inválido", http.StatusBadRequest)
		return
	}

	if body.UserID == "" {
		jsonErr(w, "user_id é obrigatório", http.StatusBadRequest)
		return
	}
	if body.TemplateBase64 == "" {
		jsonErr(w, "template_base64 é obrigatório", http.StatusBadRequest)
		return
	}
	if _, err := base64.StdEncoding.DecodeString(body.TemplateBase64); err != nil {
		jsonErr(w, "template_base64 deve ser base64 válido", http.StatusBadRequest)
		return
	}

	fingerType := body.FingerType
	if fingerType == "" {
		fingerType = "right_thumb"
	}

	var templateID int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO hardware.fingerprint_templates
		  (tenant_id, erp_user_id, erp_funcionario_id, finger_type, template_base64)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (tenant_id, erp_user_id, finger_type)
		DO UPDATE SET
		  erp_funcionario_id = EXCLUDED.erp_funcionario_id,
		  template_base64 = EXCLUDED.template_base64,
		  updated_at = NOW()
		RETURNING id`,
		user.TenantID, body.UserID, body.ERPFuncionarioID, fingerType, body.TemplateBase64,
	).Scan(&templateID)
	if err != nil {
		jsonErr(w, "erro ao registar template", http.StatusInternalServerError)
		return
	}

	jsonOK(w, FingerprintEnrollResponse{
		Success:    true,
		TemplateID: templateID,
		UserID:     body.UserID,
		Message:    "Template de impressão digital registado.",
	}, http.StatusCreated)
}

// IdentifyFingerprint identifica um utilizador a partir de um template.
// Nota: comparação exacta (placeholder); em produção usar matching de minutias.
func (h *Handler) IdentifyFingerprint(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body FingerprintIdentifyRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "body JSON inválido", http.StatusBadRequest)
		return
	}
	if body.TemplateBase64 == "" {
		jsonErr(w, "template_base64 é obrigatório", http.StatusBadRequest)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, erp_user_id, template_base64
		  FROM hardware.fingerprint_templates
		 WHERE tenant_id = $1`,
		user.TenantID,
	)
	if err != nil {
		jsonErr(w, "erro ao consultar templates", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var id int64
		var erpUserID, storedTemplate string
		if err := rows.Scan(&id, &erpUserID, &storedTemplate); err != nil {
			continue
		}
		if subtle.ConstantTimeCompare([]byte(storedTemplate), []byte(body.TemplateBase64)) == 1 {
			jsonOK(w, FingerprintIdentifyResponse{
				Success: true,
				UserID:  erpUserID,
				Message: "Impressão digital identificada.",
			}, http.StatusOK)
			return
		}
	}

	jsonOK(w, FingerprintIdentifyResponse{
		Success: false,
		Message: "Impressão digital não identificada.",
	}, http.StatusOK)
}

// DeleteFingerprintEnrollment remove o enrolamento de um utilizador.
func (h *Handler) DeleteFingerprintEnrollment(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	erpUserID := chi.URLParam(r, "user_id")
	fingerType := r.URL.Query().Get("finger_type")

	if erpUserID == "" {
		jsonErr(w, "user_id é obrigatório", http.StatusBadRequest)
		return
	}

	var err error
	if fingerType != "" {
		_, err = h.db.Exec(r.Context(), `
			DELETE FROM hardware.fingerprint_templates
			 WHERE tenant_id = $1 AND erp_user_id = $2 AND finger_type = $3`,
			user.TenantID, erpUserID, fingerType,
		)
	} else {
		_, err = h.db.Exec(r.Context(), `
			DELETE FROM hardware.fingerprint_templates
			 WHERE tenant_id = $1 AND erp_user_id = $2`,
			user.TenantID, erpUserID,
		)
	}
	if err != nil {
		jsonErr(w, "erro ao remover template", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"success": true,
		"message": "Template(s) removido(s).",
	}, http.StatusOK)
}
