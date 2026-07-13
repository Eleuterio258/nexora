package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"time"

	mw "nexora/internal/middleware"
)

// ── QR Code de assiduidade (persistido centralmente) ────────────────────────
//
// Substitui o armazenamento em memória do processo que o FaceClock usava
// (_qr_store em methods.py): não sobrevivia a reinícios nem funcionava com
// múltiplos workers/instâncias, porque cada processo tinha o seu próprio
// dict. Autenticado por API Key de device, tal como os restantes endpoints
// de assiduidade/{config,funcionarios,geofence,consentimentos}.

const (
	qrDuracaoPadraoSegundos = 60
	qrDuracaoMaximaSegundos = 300
)

// POST /api/hardware/assiduidade/qr/gerar
func (h *Handler) GerarQRDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body struct {
		LocationID      *string `json:"location_id"`
		DuracaoSegundos int     `json:"duracao_segundos"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.DuracaoSegundos <= 0 {
		body.DuracaoSegundos = qrDuracaoPadraoSegundos
	}
	if body.DuracaoSegundos > qrDuracaoMaximaSegundos {
		body.DuracaoSegundos = qrDuracaoMaximaSegundos
	}

	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	token := "qr_" + hex.EncodeToString(b)
	expiresAt := time.Now().Add(time.Duration(body.DuracaoSegundos) * time.Second)

	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO rh.qr_tokens (tenant_id, token, location_id, expires_at)
		VALUES ($1,$2,$3,$4)`,
		tenantID, token, body.LocationID, expiresAt); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"qr_code":    token,
		"expires_at": expiresAt,
	}, http.StatusCreated)
}

// POST /api/hardware/assiduidade/qr/validar
func (h *Handler) ValidarQRDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body struct {
		QRCode string `json:"qr_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.QRCode == "" {
		jsonErr(w, "qr_code é obrigatório", http.StatusBadRequest)
		return
	}

	// Marca como usado atomicamente (evita corrida entre dois pedidos
	// concorrentes a validar o mesmo QR): só actualiza, e só é "válido", se
	// ainda estava por usar e dentro do prazo — RowsAffected()==0 cobre os
	// dois casos de invalidade (já usado, ou não encontrado) e o expirado é
	// verificado à parte para dar uma mensagem mais específica.
	var locationID *string
	var expiresAt time.Time
	err = h.db.QueryRow(r.Context(),
		`SELECT location_id, expires_at FROM rh.qr_tokens WHERE token=$1 AND tenant_id=$2`,
		body.QRCode, tenantID).Scan(&locationID, &expiresAt)
	if err != nil {
		jsonErr(w, "QR Code inválido", http.StatusBadRequest)
		return
	}
	if time.Now().After(expiresAt) {
		jsonErr(w, "QR Code expirado", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(),
		`UPDATE rh.qr_tokens SET used_at = NOW() WHERE token=$1 AND tenant_id=$2 AND used_at IS NULL`,
		body.QRCode, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "QR Code já utilizado", http.StatusBadRequest)
		return
	}

	jsonOK(w, map[string]any{
		"valid":       true,
		"location_id": locationID,
	}, http.StatusOK)
}
