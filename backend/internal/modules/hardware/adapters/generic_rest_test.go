package adapters

import (
	"net/http/httptest"
	"strings"
	"testing"
)

func TestGenericRESTAdapterRejectsUnprovenFacialEvent(t *testing.T) {
	req := httptest.NewRequest("POST", "/api/hardware/events/generic", strings.NewReader(`{
		"device_serial":"mobile",
		"employee_no":"EMP-1",
		"event_time":"2026-08-02T10:00:00Z",
		"credential_type":"face"
	}`))

	if _, err := (&GenericRESTAdapter{}).ParseEvent(req); err == nil {
		t.Fatal("evento facial generico sem comprovativo deveria ser rejeitado")
	}
}

func TestGenericRESTAdapterKeepsOtherCredentialTypes(t *testing.T) {
	req := httptest.NewRequest("POST", "/api/hardware/events/generic", strings.NewReader(`{
		"device_serial":"terminal",
		"employee_no":"EMP-1",
		"event_time":"2026-08-02T10:00:00Z",
		"credential_type":"fingerprint"
	}`))

	event, err := (&GenericRESTAdapter{}).ParseEvent(req)
	if err != nil {
		t.Fatalf("fingerprint nao deveria ser afectado: %v", err)
	}
	if event.CredentialType != "fingerprint" {
		t.Fatalf("credential_type inesperado: %s", event.CredentialType)
	}
}
