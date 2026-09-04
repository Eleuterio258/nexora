package nexorapay

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestClientSendsBothAuthenticationKeys(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("X-API-Key"); got != "secret-key" {
			t.Errorf("expected X-API-Key, got %q", got)
		}
		if got := r.Header.Get("X-Public-Key"); got != "public-key" {
			t.Errorf("expected X-Public-Key, got %q", got)
		}
		if got := r.Header.Get("Idempotency-Key"); got != "payment-123" {
			t.Errorf("expected Idempotency-Key, got %q", got)
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"data":{"gatewayTransactionId":"gateway-123"}}`))
	}))
	defer server.Close()

	client := NewClient(server.URL, "secret-key", "public-key")
	_, status, err := client.Post(context.Background(), "/v1/payments", "payment-123", map[string]any{"amount": "10.00"})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if status != http.StatusCreated {
		t.Fatalf("expected 201, got %d", status)
	}
}
