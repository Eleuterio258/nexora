package handlers

import (
	"encoding/base64"
	"fmt"
	"io"
	"mime"
	"net/http"
	"strconv"
	"strings"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/pkg/faceclock"
	"nexora/internal/storage"
)

// VerificarFacialRequest é o payload JSON legacy enviado pela app no acto de marcar
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
	ImageBase64 string   `json:"image_base64,omitempty"`
	ImageURL    string   `json:"image_url,omitempty"`
	GeoLat      *float64 `json:"geo_lat,omitempty"`
	GeoLng      *float64 `json:"geo_lng,omitempty"`
}

// VerificarFacial faz o proxy da verificação facial para o FaceClock
// (POST /api/v1/biometric/verify) — substitui a chamada directa app→FaceClock
// que existia antes (AssiduidadeApiService.verifyFace no Android), para que
// seja sempre o ERP a iniciar a comunicação com o FaceClock, tal como já
// acontece no enrollment (recursos-humanos.EnrollFacial).
//
// Suporta JSON legacy (image_base64) ou multipart/form-data (image como ficheiro).
// Em multipart, a imagem é guardada em MinIO e enviada ao FaceClock por URL.
// A resposta inclui foto_url para a app incluir no POST /ponto.
func (h *Handler) VerificarFacial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var deviceID string
	var imageBase64 string
	var imageURL string
	var geoLat, geoLng *float64

	if strings.Contains(r.Header.Get("Content-Type"), "multipart/form-data") {
		parsedURL, parsedBase64, parsedDeviceID, parsedGeoLat, parsedGeoLng, err := h.parseVerifyMultipart(r, w)
		if err != nil {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		imageURL = parsedURL
		imageBase64 = parsedBase64
		deviceID = parsedDeviceID
		geoLat = parsedGeoLat
		geoLng = parsedGeoLng
	} else {
		var body VerificarFacialRequest
		if err := decodeJSON(r, &body); err != nil {
			jsonErr(w, "Payload inválido", http.StatusBadRequest)
			return
		}
		if body.DeviceID == "" || body.ImageBase64 == "" {
			jsonErr(w, "device_id e image_base64 são obrigatórios", http.StatusBadRequest)
			return
		}
		deviceID = body.DeviceID
		imageBase64 = body.ImageBase64
		geoLat = body.GeoLat
		geoLng = body.GeoLng
	}

	faceClockReq := faceClockVerifyRequest{
		UserID:      fmt.Sprintf("%d", user.ID),
		DeviceID:    deviceID,
		ImageBase64: imageBase64,
		GeoLat:      geoLat,
		GeoLng:      geoLng,
	}

	client := faceclock.NewClient(h.cfg.FaceClockBaseURL, h.cfg.FaceClockAccessKeyID, h.cfg.FaceClockSecretAccessKey)
	result, statusCode, err := client.Post(r.Context(), "/api/v1/biometric/verify", faceClockReq)
	if err != nil {
		jsonErr(w, fmt.Sprintf("Erro ao comunicar com FaceClock: %s", err.Error()), http.StatusBadGateway)
		return
	}

	// Adicionar foto_url à resposta para a app incluir no POST /ponto.
	if imageURL != "" && statusCode < 400 && result != nil {
		result["foto_url"] = imageURL
	}

	jsonOK(w, result, statusCode)
}

// parseVerifyMultipart processa um pedido multipart/form-data de verificação
// facial, fazendo upload da selfie para MinIO e devolvendo a URL pública e o
// base64 da imagem (para envio ao FaceClock sem depender de URL pública).
func (h *Handler) parseVerifyMultipart(r *http.Request, w http.ResponseWriter) (string, string, string, *float64, *float64, error) {
	const maxBytes = 10 * 1024 * 1024 // 10 MB
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes+1024)
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		return "", "", "", nil, nil, fmt.Errorf("falha ao processar multipart: %v", err)
	}

	deviceID := r.FormValue("device_id")
	if deviceID == "" {
		return "", "", "", nil, nil, fmt.Errorf("device_id é obrigatório")
	}

	var geoLat, geoLng *float64
	if raw := r.FormValue("geo_lat"); raw != "" {
		v, err := strconv.ParseFloat(raw, 64)
		if err == nil {
			geoLat = &v
		}
	}
	if raw := r.FormValue("geo_lng"); raw != "" {
		v, err := strconv.ParseFloat(raw, 64)
		if err == nil {
			geoLng = &v
		}
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		return "", "", "", nil, nil, fmt.Errorf("campo 'image' em falta")
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		return "", "", "", nil, nil, fmt.Errorf("erro ao ler imagem: %v", err)
	}
	if len(data) == 0 {
		return "", "", "", nil, nil, fmt.Errorf("imagem vazia")
	}

	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = http.DetectContentType(data)
	}
	if !strings.HasPrefix(contentType, "image/") {
		return "", "", "", nil, nil, fmt.Errorf("ficheiro não é uma imagem")
	}

	exts, _ := mime.ExtensionsByType(contentType)
	ext := ".jpg"
	if len(exts) > 0 {
		ext = exts[0]
	}
	imageBase64 := base64.StdEncoding.EncodeToString(data)

	user := mw.GetUser(r)
	ctx := r.Context()
	now := time.Now().UTC().UnixMilli()
	key := storage.JoinPath(
		"uploads",
		fmt.Sprintf("tenant-%d", user.TenantID),
		"biometria",
		"verify",
		fmt.Sprintf("user-%d", user.ID),
		fmt.Sprintf("%d-%s-%d%s", now, deviceID, header.Size, ext),
	)
	url, err := h.storage.Put(ctx, key, data, contentType)
	if err != nil {
		return "", "", "", nil, nil, fmt.Errorf("erro ao guardar imagem: %v", err)
	}

	return url, imageBase64, deviceID, geoLat, geoLng, nil
}
