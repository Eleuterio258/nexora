package handlers

import (
	"context"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
	"nexora/internal/pkg/tenantid"
)

// FingerprintEnrollRequest representa o body para registo de um template.
// Aceita qualquer um dos identificadores de funcionário; o sistema resolve
// automaticamente para o identificador canónico interno (funcionario_id).
type FingerprintEnrollRequest struct {
	FuncionarioID    *int64  `json:"funcionario_id,omitempty"`
	EmployeeNo       *string `json:"employee_no,omitempty"`
	UserID           *string `json:"user_id,omitempty"`
	ERPFuncionarioID *string `json:"erp_funcionario_id,omitempty"`
	FingerType       string  `json:"finger_type"`
	TemplateBase64   string  `json:"template_base64"`
}

// FingerprintEnrollResponse representa a resposta de um registo bem-sucedido.
type FingerprintEnrollResponse struct {
	Success          bool   `json:"success"`
	TemplateID       int64  `json:"template_id"`
	UserID           string `json:"user_id"`
	FuncionarioID    int64  `json:"funcionario_id"`
	EmployeeNo       string `json:"employee_no,omitempty"`
	Message          string `json:"message"`
}

// FingerprintIdentifyRequest representa o body para identificação 1:N.
type FingerprintIdentifyRequest struct {
	TemplateBase64 string `json:"template_base64"`
}

// FingerprintIdentifyResponse representa a resposta de identificação.
type FingerprintIdentifyResponse struct {
	Success       bool   `json:"success"`
	UserID        string `json:"user_id,omitempty"`
	FuncionarioID int64  `json:"funcionario_id,omitempty"`
	EmployeeNo    string `json:"employee_no,omitempty"`
	Message       string `json:"message"`
}

// resolveFuncionarioFingerprint resolve a identidade do funcionário a partir
// de um dos identificadores aceites (funcionario_id, employee_no ou user_id).
// O tenant esperado é o da empresa (hardware.devices.tenant_id); é traduzido
// para o tenant SaaS antes de consultar rh.funcionarios.
func (h *Handler) resolveFuncionarioFingerprint(ctx context.Context, companyTenantID int64, body *FingerprintEnrollRequest) (*funcionario.Identity, error) {
	saasTenantID, err := tenantid.ResolveSaas(ctx, h.db, companyTenantID)
	if err != nil {
		return nil, fmt.Errorf("tenant não resolvido")
	}

	svc := funcionario.NewService(h.db)

	switch {
	case body.FuncionarioID != nil && *body.FuncionarioID > 0:
		return svc.PorID(ctx, saasTenantID, *body.FuncionarioID)
	case body.EmployeeNo != nil && *body.EmployeeNo != "":
		return svc.PorEmployeeNo(ctx, saasTenantID, *body.EmployeeNo)
	case body.UserID != nil && *body.UserID != "":
		uid, err := strconv.ParseInt(*body.UserID, 10, 64)
		if err != nil {
			return nil, fmt.Errorf("user_id inválido")
		}
		return svc.PorUserID(ctx, saasTenantID, uid)
	default:
		return nil, fmt.Errorf("funcionario_id, employee_no ou user_id é obrigatório")
	}
}

// EnrollFingerprint regista ou actualiza um template de impressão digital.
func (h *Handler) EnrollFingerprint(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body FingerprintEnrollRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "body JSON inválido", http.StatusBadRequest)
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

	f, err := h.resolveFuncionarioFingerprint(r.Context(), user.TenantID, &body)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}
	if err := f.VerificarAtivo(); err != nil {
		jsonErr(w, "funcionário inativo", http.StatusForbidden)
		return
	}

	fingerType := body.FingerType
	if fingerType == "" {
		fingerType = "right_thumb"
	}

	erpUserID := ""
	if f.UserID != nil {
		erpUserID = strconv.FormatInt(*f.UserID, 10)
	}
	erpFuncionarioID := strconv.FormatInt(f.ID, 10)

	var templateID int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO hardware.fingerprint_templates
		  (tenant_id, erp_user_id, erp_funcionario_id, finger_type, template_base64)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (tenant_id, erp_user_id, finger_type)
		DO UPDATE SET
		  erp_funcionario_id = EXCLUDED.erp_funcionario_id,
		  template_base64 = EXCLUDED.template_base64,
		  updated_at = NOW()
		RETURNING id`,
		user.TenantID, erpUserID, &erpFuncionarioID, fingerType, body.TemplateBase64,
	).Scan(&templateID)
	if err != nil {
		jsonErr(w, "erro ao registar template", http.StatusInternalServerError)
		return
	}

	resp := FingerprintEnrollResponse{
		Success:       true,
		TemplateID:    templateID,
		UserID:        erpUserID,
		FuncionarioID: f.ID,
		Message:       "Template de impressão digital registado.",
	}
	if f.NumeroFuncionario != nil {
		resp.EmployeeNo = *f.NumeroFuncionario
	}
	jsonOK(w, resp, http.StatusCreated)
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
		SELECT id, erp_user_id, erp_funcionario_id, template_base64
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
		var erpUserID, erpFuncionarioID, storedTemplate string
		if err := rows.Scan(&id, &erpUserID, &erpFuncionarioID, &storedTemplate); err != nil {
			continue
		}
		if subtle.ConstantTimeCompare([]byte(storedTemplate), []byte(body.TemplateBase64)) == 1 {
			funcionarioID, _ := strconv.ParseInt(erpFuncionarioID, 10, 64)
			jsonOK(w, FingerprintIdentifyResponse{
				Success:       true,
				UserID:        erpUserID,
				FuncionarioID: funcionarioID,
				Message:       "Impressão digital identificada.",
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
// Aceita user_id ou funcionario_id na URL.
func (h *Handler) DeleteFingerprintEnrollment(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	paramUserID := chi.URLParam(r, "user_id")

	if paramUserID == "" {
		jsonErr(w, "user_id é obrigatório", http.StatusBadRequest)
		return
	}

	erpUserID := paramUserID
	// Se o valor não for numérico puro, assume funcionario_id e resolve user_id.
	if _, err := strconv.ParseInt(paramUserID, 10, 64); err != nil {
		saasTenantID, terr := tenantid.ResolveSaas(r.Context(), h.db, user.TenantID)
		if terr != nil {
			jsonErr(w, "tenant não resolvido", http.StatusInternalServerError)
			return
		}
		svc := funcionario.NewService(h.db)
		funcionarioID, err := strconv.ParseInt(paramUserID, 10, 64)
		if err != nil {
			jsonErr(w, "funcionario_id inválido", http.StatusBadRequest)
			return
		}
		f, err := svc.PorID(r.Context(), saasTenantID, funcionarioID)
		if err != nil {
			jsonErr(w, "funcionário não encontrado", http.StatusNotFound)
			return
		}
		if f.UserID == nil {
			jsonErr(w, "funcionário sem user_id associado", http.StatusUnprocessableEntity)
			return
		}
		erpUserID = strconv.FormatInt(*f.UserID, 10)
	}

	fingerType := r.URL.Query().Get("finger_type")

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
