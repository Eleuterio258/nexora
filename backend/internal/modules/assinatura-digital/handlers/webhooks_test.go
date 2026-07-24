package handlers

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/pashagolub/pgxmock/v4"

	"nexora/config"
)

func signWebhook(secret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil))
}

func TestReceberWebhook_SemConfiguracao(t *testing.T) {
	h := &Handler{cfg: &config.Config{}}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotImplemented {
		t.Errorf("status = %d, want %d", rr.Code, http.StatusNotImplemented)
	}
}

func TestReceberWebhook_AssinaturaInvalida(t *testing.T) {
	h := &Handler{cfg: &config.Config{SignatureWebhookSecret: "segredo"}}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader([]byte(`{}`)))
	req.Header.Set("X-Signature", "invalida")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Errorf("status = %d, want %d", rr.Code, http.StatusUnauthorized)
	}
}

func TestReceberWebhook_EventoJaProcessado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	cfg := &config.Config{SignatureWebhookSecret: "segredo"}
	h := &Handler{cfg: cfg, db: mock}

	payload := map[string]any{
		"event_id":   "evt-001",
		"event_type": "signature.completed",
		"timestamp":  time.Now().UTC(),
		"nonce":      "abc123",
		"signatario_id": 20,
	}
	body, _ := json.Marshal(payload)

	mock.ExpectQuery("SELECT EXISTS").
		WithArgs("intic", "evt-001").
		WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(true))

	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if !strings.Contains(rr.Body.String(), "já processado") {
		t.Errorf("esperava mensagem de idempotência, body=%s", rr.Body.String())
	}
}

func TestReceberWebhook_SignatureCompleted(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	cfg := &config.Config{SignatureWebhookSecret: "segredo"}
	h := &Handler{cfg: cfg, db: mock}

	sigID := int64(20)
	docID := int64(10)
	payload := map[string]any{
		"event_id":      "evt-002",
		"event_type":    "signature.completed",
		"timestamp":     time.Now().UTC(),
		"nonce":         "def456",
		"signatario_id": sigID,
	}
	body, _ := json.Marshal(payload)

	mock.ExpectQuery("SELECT EXISTS").
		WithArgs("intic", "evt-002").
		WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(false))

	mock.ExpectExec("INSERT INTO assinatura_digital.webhook_events").
		WithArgs(
			pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(),
		).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	mock.ExpectExec("UPDATE assinatura_digital.signatarios").
		WithArgs(sigID).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	mock.ExpectQuery("SELECT documento_id FROM assinatura_digital.signatarios").
		WithArgs(sigID).
		WillReturnRows(pgxmock.NewRows([]string{"documento_id"}).AddRow(docID))

	mock.ExpectQuery("SELECT COUNT").
		WithArgs(docID).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(0))

	mock.ExpectExec("UPDATE assinatura_digital.documentos").
		WithArgs("assinado", docID).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	mock.ExpectExec("INSERT INTO assinatura_digital.logs").
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	mock.ExpectExec("UPDATE assinatura_digital.webhook_events SET processado=TRUE").
		WithArgs("intic", "evt-002").
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
}

func TestReceberWebhook_EventoAntigo(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	cfg := &config.Config{SignatureWebhookSecret: "segredo"}
	h := &Handler{cfg: cfg, db: mock}

	payload := map[string]any{
		"event_id":   "evt-003",
		"event_type": "signature.completed",
		"timestamp":  time.Now().Add(-10 * time.Minute).UTC(),
		"nonce":      "ghi789",
	}
	body, _ := json.Marshal(payload)

	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}
