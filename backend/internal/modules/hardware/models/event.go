package models

import "time"

// NormalizedEvent representa um evento de hardware já normalizado,
// independente do fabricante ou protocolo.
type NormalizedEvent struct {
	DeviceSerial   string
	DeviceModel    string
	EmployeeNo     string
	EventType      string    // access_granted, access_denied, unknown
	EventTime      time.Time
	Direction      string    // entry, exit, unknown
	CredentialType string    // face, card, fingerprint, pin
	RawPayload     []byte
}

// EventTypeValid verifica se o tipo de evento é conhecido.
func (e NormalizedEvent) EventTypeValid() bool {
	switch e.EventType {
	case "access_granted", "access_denied", "unknown":
		return true
	}
	return false
}

// DirectionValid verifica se a direção é conhecida.
func (e NormalizedEvent) DirectionValid() bool {
	switch e.Direction {
	case "entry", "exit", "unknown":
		return true
	}
	return false
}
