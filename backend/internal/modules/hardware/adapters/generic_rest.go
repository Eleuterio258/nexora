package adapters

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/hardware/models"
)

// GenericRESTAdapter aceita eventos no formato normalizado genérico.
type GenericRESTAdapter struct{}

func (a *GenericRESTAdapter) Name() string {
	return "generic_rest"
}

// GenericPayload representa o contrato REST genérico.
type GenericPayload struct {
	DeviceSerial   string `json:"device_serial"`
	EmployeeNo     string `json:"employee_no"`
	EventTime      string `json:"event_time"`
	EventType      string `json:"event_type"`
	Direction      string `json:"direction"`
	CredentialType string `json:"credential_type"`
}

func (a *GenericRESTAdapter) ParseEvent(r *http.Request) (*models.NormalizedEvent, error) {
	var payload GenericPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		return nil, err
	}

	if payload.EmployeeNo == "" || payload.EventTime == "" {
		return nil, errors.New("employee_no e event_time são obrigatórios")
	}

	eventTime, err := time.Parse(time.RFC3339, payload.EventTime)
	if err != nil {
		return nil, errors.New("event_time deve estar no formato RFC3339")
	}

	eventType := payload.EventType
	if eventType == "" {
		eventType = "access_granted"
	}
	direction := payload.Direction
	if direction == "" {
		direction = "unknown"
	}
	credentialType := payload.CredentialType
	if credentialType == "" {
		credentialType = "unknown"
	}

	raw, _ := json.Marshal(payload)

	return &models.NormalizedEvent{
		DeviceSerial:   payload.DeviceSerial,
		EmployeeNo:     payload.EmployeeNo,
		EventType:      eventType,
		EventTime:      eventTime,
		Direction:      direction,
		CredentialType: credentialType,
		RawPayload:     raw,
	}, nil
}

func (a *GenericRESTAdapter) ValidateAuth(r *http.Request, device *mw.DeviceInfo, configs map[string]string) error {
	secret, hasSecret := configs["webhook.secret"]
	if !hasSecret || secret == "" {
		return nil
	}

	sig := r.Header.Get("X-Signature")
	if sig == "" {
		return errors.New("assinatura em falta")
	}

	parts := strings.SplitN(sig, "=", 2)
	if len(parts) != 2 || parts[0] != "sha256" {
		return errors.New("formato de assinatura inválido")
	}

	body := make([]byte, r.ContentLength)
	if _, err := r.Body.Read(body); err != nil && err.Error() != "EOF" {
		return fmt.Errorf("erro ao ler body: %w", err)
	}

	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))

	if !hmac.Equal([]byte(parts[1]), []byte(expected)) {
		return errors.New("assinatura inválida")
	}
	return nil
}
