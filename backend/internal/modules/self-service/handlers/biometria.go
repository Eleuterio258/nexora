package handlers

import (
	"fmt"
	"net/http"

	mw "nexora/internal/middleware"
	"nexora/internal/pkg/faceclock"
)

// VerificarFacialRequest é o payload enviado pela app no acto de marcar
// ponto por reconhecimento facial.
type VerificarFacialRequest struct {
	DeviceID    string   `json:"device_id"`
	ImageBase64 string   `json:"image_base64"`
	GeoLat      *float64 `json:"geo_lat"`
	GeoLng      *float64 `json:"geo_lng"`
}

// faceClockVerifyRequest é o formato esperado pelo FaceClock (VerifyRequest,
// app/schemas/requests.py) — inclui user_id, que o ERP preenche a partir do
// utilizador autenticado, nunca do payload recebido da app (mesma classe de
// protecção já aplicada em POST /clock/register no FaceClock: um COLABORADOR
// não pode verificar-se como outro utilizador só por enviar um id diferente).
type faceClockVerifyRequest struct {
	UserID      string   `json:"user_id"`
	DeviceID    string   `json:"device_id"`
	ImageBase64 string   `json:"image_base64"`
	GeoLat      *float64 `json:"geo_lat,omitempty"`
	GeoLng      *float64 `json:"geo_lng,omitempty"`
}

// VerificarFacial faz o proxy da verificação facial para o FaceClock
// (POST /api/v1/biometric/verify) — substitui a chamada directa app→FaceClock
// que existia antes (AssiduidadeApiService.verifyFace no Android), para que
// seja sempre o ERP a iniciar a comunicação com o FaceClock, tal como já
// acontece no enrollment (recursos-humanos.EnrollFacial).
func (h *Handler) VerificarFacial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body VerificarFacialRequest
	if err := decodeJSON(r, &body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if body.DeviceID == "" || body.ImageBase64 == "" {
		jsonErr(w, "device_id e image_base64 são obrigatórios", http.StatusBadRequest)
		return
	}

	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		jsonErr(w, "Cabeçalho Authorization em falta", http.StatusUnauthorized)
		return
	}

	faceClockReq := faceClockVerifyRequest{
		UserID:      fmt.Sprintf("%d", user.ID),
		DeviceID:    body.DeviceID,
		ImageBase64: body.ImageBase64,
		GeoLat:      body.GeoLat,
		GeoLng:      body.GeoLng,
	}

	client := faceclock.NewClient(h.cfg.FaceClockBaseURL)
	result, statusCode, err := client.PostAsUser(r.Context(), "/api/v1/biometric/verify", authHeader, faceClockReq)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}
	jsonOK(w, result, statusCode)
}
