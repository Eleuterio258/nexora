package handlers

import (
	"fmt"
	"net/http"

	mw "nexora/internal/middleware"
	"nexora/internal/pkg/faceclock"
)

// faceClockLivenessChallengeRequest é o formato enviado ao FaceClock.
type faceClockLivenessChallengeRequest struct {
	UserID string `json:"user_id"`
}

// LivenessVerifyRequest é o payload recebido da app para validar o desafio.
type LivenessVerifyRequest struct {
	ChallengeID string    `json:"challenge_id"`
	DeviceID    string    `json:"device_id"`
	Frames      []string  `json:"frames_base64"`
	GeoLat      *float64  `json:"geo_lat,omitempty"`
	GeoLng      *float64  `json:"geo_lng,omitempty"`
}

// faceClockLivenessVerifyRequest é o formato enviado ao FaceClock.
type faceClockLivenessVerifyRequest struct {
	ChallengeID string    `json:"challenge_id"`
	UserID      string    `json:"user_id"`
	DeviceID    string    `json:"device_id"`
	Frames      []string  `json:"frames_base64"`
	GeoLat      *float64  `json:"geo_lat,omitempty"`
	GeoLng      *float64  `json:"geo_lng,omitempty"`
}

// LivenessChallenge pede ao FaceClock um desafio de prova de vida (piscar,
// sorrir ou virar o rosto). O desafio é válido por 45s e está vinculado ao
// utilizador autenticado.
func (h *Handler) LivenessChallenge(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Post(
		r.Context(),
		"/api/v1/liveness/challenge",
		faceClockLivenessChallengeRequest{UserID: fmt.Sprintf("%d", user.ID)},
	)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}

	jsonOK(w, result, statusCode)
}

// LivenessVerify faz proxy da validação do desafio de prova de vida + match
// facial para o FaceClock. Se o desafio for cumprido e houver match, o
// FaceClock devolve um verification_token que a app deve usar no POST /ponto.
func (h *Handler) LivenessVerify(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	// FaceClock aceita no máximo 20 frames por desafio (frames_base64,
	// max_length=20); 30MB cobre folgadamente esse limite sem deixar um
	// pedido crescer sem controlo.
	const maxBytes = 30 * 1024 * 1024
	const maxFrames = 20
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes)

	var body LivenessVerifyRequest
	if err := decodeJSON(r, &body); err != nil {
		jsonErr(w, "Payload inválido ou demasiado grande", http.StatusBadRequest)
		return
	}
	if body.ChallengeID == "" || body.DeviceID == "" || len(body.Frames) == 0 {
		jsonErr(w, "challenge_id, device_id e frames_base64 são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.Frames) > maxFrames {
		jsonErr(w, fmt.Sprintf("frames_base64 excede o máximo de %d frames", maxFrames), http.StatusBadRequest)
		return
	}

	faceClockReq := faceClockLivenessVerifyRequest{
		ChallengeID: body.ChallengeID,
		UserID:      fmt.Sprintf("%d", user.ID),
		DeviceID:    body.DeviceID,
		Frames:      body.Frames,
		GeoLat:      body.GeoLat,
		GeoLng:      body.GeoLng,
	}

	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Post(r.Context(), "/api/v1/liveness/verify", faceClockReq)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}

	jsonOK(w, result, statusCode)
}
