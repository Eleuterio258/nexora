package adapters

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/hardware/models"
)

// HikvisionAdapter normaliza eventos dos terminais Hikvision ISAPI.
type HikvisionAdapter struct{}

func (a *HikvisionAdapter) Name() string {
	return "hikvision"
}

// HikvisionPayload representa o payload típico enviado pelos terminais Hikvision.
type HikvisionPayload struct {
	EventType             string                `json:"eventType"`
	AccessControllerEvent HikvisionAccessEvent  `json:"AccessControllerEvent"`
}

type HikvisionAccessEvent struct {
	DeviceName       string `json:"deviceName"`
	MajorEventType   int    `json:"majorEventType"`
	SubEventType     int    `json:"subEventType"`
	EmployeeNoString string `json:"employeeNoString"`
	Name             string `json:"name"`
	CardNo           string `json:"cardNo"`
	Time             string `json:"time"`
	SerialNo         int64  `json:"serialNo"`
}

func (a *HikvisionAdapter) ParseEvent(r *http.Request) (*models.NormalizedEvent, error) {
	var payload HikvisionPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		return nil, err
	}

	event := payload.AccessControllerEvent
	if event.EmployeeNoString == "" || event.Time == "" {
		return nil, errors.New("employeeNoString e time são obrigatórios")
	}

	eventTime, err := parseHikvisionTime(event.Time)
	if err != nil {
		return nil, err
	}

	raw, _ := json.Marshal(payload)

	return &models.NormalizedEvent{
		DeviceSerial:   event.DeviceName,
		EmployeeNo:     event.EmployeeNoString,
		EventType:      "access_granted",
		EventTime:      eventTime,
		Direction:      "unknown",
		CredentialType: "face",
		RawPayload:     raw,
	}, nil
}

func (a *HikvisionAdapter) ValidateAuth(r *http.Request, device *mw.DeviceInfo, configs map[string]string) error {
	// A autenticação principal é feita por API Key no middleware.
	// Aqui podem ser adicionadas validações específicas (ex: HMAC ISAPI).
	return nil
}

func parseHikvisionTime(s string) (time.Time, error) {
	layouts := []string{
		time.RFC3339,
		"2006-01-02T15:04:05-07:00",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
	}
	for _, layout := range layouts {
		if t, err := time.Parse(layout, s); err == nil {
			return t, nil
		}
	}
	return time.Time{}, errors.New("formato de data/hora inválido")
}
