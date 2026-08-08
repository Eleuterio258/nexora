package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"nexora/config"
	"nexora/internal/pkg/faceclock"
)

// Handler expõe métricas e logs do FaceClock via proxy HMAC.
type Handler struct {
	cfg config.Config
}

// New cria um handler de monitorização do FaceClock.
func New(cfg config.Config) *Handler {
	return &Handler{cfg: cfg}
}

// Metrics faz proxy do endpoint Prometheus /metrics do FaceClock.
func (h *Handler) Metrics(w http.ResponseWriter, r *http.Request) {
	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Get(r.Context(), "/metrics", "")
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}
	if raw, ok := result["raw"].(string); ok {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(statusCode)
		_, _ = w.Write([]byte(raw))
		return
	}
	jsonOK(w, result, statusCode)
}

// AuditLogs faz proxy do endpoint /audit/logs do FaceClock.
func (h *Handler) AuditLogs(w http.ResponseWriter, r *http.Request) {
	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Get(r.Context(), "/api/v1/audit/logs", "")
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}
	jsonOK(w, result, statusCode)
}

func jsonOK(w http.ResponseWriter, v any, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func jsonErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
