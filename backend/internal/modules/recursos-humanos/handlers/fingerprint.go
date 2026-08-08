package handlers

import (
	"fmt"
	"net/http"
	"net/url"

	"github.com/go-chi/chi/v5"

	"nexora/internal/pkg/faceclock"
)

// FingerprintEnrollRequest é o payload para registo de impressão digital.
type FingerprintEnrollRequest struct {
	UserID          string `json:"user_id"`
	ErpFuncionarioID string `json:"erp_funcionario_id,omitempty"`
	FingerType      string `json:"finger_type"`
	TemplateBase64  string `json:"template_base64"`
}

// FingerprintIdentifyRequest é o payload para identificação 1:N.
type FingerprintIdentifyRequest struct {
	TemplateBase64 string `json:"template_base64"`
}

// FingerprintEnroll faz proxy do registo de impressão digital para o FaceClock.
func (h *Handler) FingerprintEnroll(w http.ResponseWriter, r *http.Request) {
	var body FingerprintEnrollRequest
	if err := decodeJSON(r, &body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if body.UserID == "" || body.TemplateBase64 == "" {
		jsonErr(w, "user_id e template_base64 são obrigatórios", http.StatusBadRequest)
		return
	}

	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Post(r.Context(), "/api/v1/fingerprint/enroll", body)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}
	jsonOK(w, result, statusCode)
}

// FingerprintIdentify faz proxy da identificação 1:N para o FaceClock.
func (h *Handler) FingerprintIdentify(w http.ResponseWriter, r *http.Request) {
	var body FingerprintIdentifyRequest
	if err := decodeJSON(r, &body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if body.TemplateBase64 == "" {
		jsonErr(w, "template_base64 é obrigatório", http.StatusBadRequest)
		return
	}

	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Post(r.Context(), "/api/v1/fingerprint/identify", body)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}
	jsonOK(w, result, statusCode)
}

// FingerprintDelete faz proxy da remoção de enrolamento para o FaceClock.
func (h *Handler) FingerprintDelete(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "user_id")
	if userID == "" {
		jsonErr(w, "user_id é obrigatório", http.StatusBadRequest)
		return
	}

	fingerType := r.URL.Query().Get("finger_type")
	path := fmt.Sprintf("/api/v1/fingerprint/enroll/%s", userID)
	query := ""
	if fingerType != "" {
		query = url.Values{"finger_type": {fingerType}}.Encode()
	}

	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Delete(r.Context(), path, query)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}
	jsonOK(w, result, statusCode)
}
