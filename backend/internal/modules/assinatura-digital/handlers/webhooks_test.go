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
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/pashagolub/pgxmock/v4"

	"nexora/config"
)

func signWebhook(secret string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil))
}

func webhookTestConfig() *config.Config {
	return &config.Config{
		SignatureWebhookEnabled:   true,
		SignatureWebhookProviders: []string{"intic"},
		SignatureWebhookSecrets:   map[string]string{"intic": "segredo"},
	}
}

func TestReceberWebhook_Desativado(t *testing.T) {
	cfg := webhookTestConfig()
	cfg.SignatureWebhookEnabled = false
	h := &Handler{cfg: cfg}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader([]byte(`{}`)))
	req.Header.Set("X-Signature", "qualquer")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Errorf("status = %d, want %d", rr.Code, http.StatusServiceUnavailable)
	}
}

func TestReceberWebhook_ProviderNaoPermitido(t *testing.T) {
	h := &Handler{cfg: webhookTestConfig()}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/outro-provider", bytes.NewReader([]byte(`{}`)))
	req.Header.Set("X-Signature", "qualquer")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("status = %d, want %d", rr.Code, http.StatusForbidden)
	}
}

func TestReceberWebhook_SemSegredoConfigurado(t *testing.T) {
	cfg := webhookTestConfig()
	cfg.SignatureWebhookSecrets = map[string]string{}
	h := &Handler{cfg: cfg}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader([]byte(`{}`)))
	req.Header.Set("X-Signature", "qualquer")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotImplemented {
		t.Errorf("status = %d, want %d", rr.Code, http.StatusNotImplemented)
	}
}

func TestReceberWebhook_AssinaturaInvalida(t *testing.T) {
	h := &Handler{cfg: webhookTestConfig()}
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

func TestReceberWebhook_TenantIDObrigatorio(t *testing.T) {
	h := &Handler{cfg: webhookTestConfig()}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	payload := map[string]any{
		"event_id":   "evt-tenant",
		"event_type": "signature.completed",
		"timestamp":  time.Now().UTC(),
	}
	body, _ := json.Marshal(payload)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}

func TestReceberWebhook_EventoAntigo(t *testing.T) {
	h := &Handler{cfg: webhookTestConfig()}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	payload := map[string]any{
		"event_id":   "evt-003",
		"event_type": "signature.completed",
		"timestamp":  time.Now().Add(-10 * time.Minute).UTC(),
		"nonce":      "ghi789",
		"tenant_id":  10,
	}
	body, _ := json.Marshal(payload)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}

func TestReceberWebhook_EventoNoFuturo(t *testing.T) {
	h := &Handler{cfg: webhookTestConfig()}
	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	payload := map[string]any{
		"event_id":   "evt-004",
		"event_type": "signature.completed",
		"timestamp":  time.Now().Add(10 * time.Minute).UTC(),
		"nonce":      "jkl012",
		"tenant_id":  10,
	}
	body, _ := json.Marshal(payload)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}

func TestReceberWebhook_EventoJaProcessado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{cfg: webhookTestConfig(), db: mock}

	payload := map[string]any{
		"event_id":      "evt-001",
		"event_type":    "signature.completed",
		"timestamp":     time.Now().UTC(),
		"nonce":         "abc123",
		"tenant_id":     10,
		"signatario_id": 20,
	}
	body, _ := json.Marshal(payload)

	// ON CONFLICT DO NOTHING não devolve linha: o evento já existe.
	mock.ExpectQuery("INSERT INTO assinatura_digital.webhook_events").
		WithArgs("intic", "evt-001", "signature.completed", pgxmock.AnyArg(), pgxmock.AnyArg(), int64(10)).
		WillReturnRows(pgxmock.NewRows([]string{"id"}))
	mock.ExpectQuery("SELECT id, processado FROM assinatura_digital.webhook_events").
		WithArgs("intic", "evt-001").
		WillReturnRows(pgxmock.NewRows([]string{"id", "processado"}).AddRow(int64(1), true))

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
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}

func TestReceberWebhook_NonceReutilizado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{cfg: webhookTestConfig(), db: mock}

	payload := map[string]any{
		"event_id":   "evt-nonce-novo",
		"event_type": "signature.completed",
		"timestamp":  time.Now().UTC(),
		"nonce":      "nonce-reutilizado",
		"tenant_id":  10,
	}
	body, _ := json.Marshal(payload)

	mock.ExpectQuery("INSERT INTO assinatura_digital.webhook_events").
		WithArgs("intic", "evt-nonce-novo", "signature.completed", pgxmock.AnyArg(), pgxmock.AnyArg(), int64(10)).
		WillReturnError(&pgconn.PgError{Code: "23505", ConstraintName: "uq_webhook_events_provider_nonce"})

	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusConflict {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusConflict, rr.Body.String())
	}
}

// TestReceberWebhook_SignatureCompleted cobre o caminho feliz sem evidência
// do provider (dev/intic-stub não usam webhook): o signatário/documento
// ficam em "aceite_eletronicamente", nunca "assinado".
func TestReceberWebhook_SignatureCompleted(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{cfg: webhookTestConfig(), db: mock}

	sigID := int64(20)
	docID := int64(10)
	tenantID := int64(10)
	payload := map[string]any{
		"event_id":      "evt-002",
		"event_type":    "signature.completed",
		"timestamp":     time.Now().UTC(),
		"nonce":         "def456",
		"tenant_id":     tenantID,
		"signatario_id": sigID,
	}
	body, _ := json.Marshal(payload)

	mock.ExpectQuery("INSERT INTO assinatura_digital.webhook_events").
		WithArgs("intic", "evt-002", "signature.completed", pgxmock.AnyArg(), pgxmock.AnyArg(), tenantID).
		WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow(int64(1)))

	mock.ExpectBegin()

	mock.ExpectQuery("SELECT s.documento_id, s.tenant_id, d.tenant_id, s.status").
		WithArgs(sigID).
		WillReturnRows(pgxmock.NewRows([]string{"documento_id", "tenant_id", "tenant_id", "status"}).
			AddRow(docID, tenantID, tenantID, "convidado"))

	mock.ExpectExec("UPDATE assinatura_digital.signatarios").
		WithArgs("aceite_eletronicamente", sigID).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	mock.ExpectQuery("SELECT COUNT").
		WithArgs(docID).
		WillReturnRows(pgxmock.NewRows([]string{"pendentes", "nao_criptografados"}).AddRow(0, 1))

	mock.ExpectExec("UPDATE assinatura_digital.documentos").
		WithArgs("aceite_eletronicamente", docID, tenantID).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	mock.ExpectExec("INSERT INTO assinatura_digital.logs").
		WithArgs(pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg()).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	mock.ExpectExec("UPDATE assinatura_digital.webhook_events SET processado=TRUE").
		WithArgs(int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	mock.ExpectCommit()

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
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}

// TestReceberWebhook_TenantNaoCorresponde confirma que o evento é rejeitado
// (e a transação revertida) quando o tenant_id do payload não corresponde ao
// tenant real do signatário/documento — o webhook nunca deve mutar dados de
// um tenant diferente do que o provider alega.
func TestReceberWebhook_TenantNaoCorresponde(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{cfg: webhookTestConfig(), db: mock}

	sigID := int64(20)
	docID := int64(10)
	payload := map[string]any{
		"event_id":      "evt-tenant-mismatch",
		"event_type":    "signature.completed",
		"timestamp":     time.Now().UTC(),
		"nonce":         "tenant-mismatch",
		"tenant_id":     999, // não corresponde ao tenant real (10)
		"signatario_id": sigID,
	}
	body, _ := json.Marshal(payload)

	mock.ExpectQuery("INSERT INTO assinatura_digital.webhook_events").
		WithArgs("intic", "evt-tenant-mismatch", "signature.completed", pgxmock.AnyArg(), pgxmock.AnyArg(), int64(999)).
		WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow(int64(2)))

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT s.documento_id, s.tenant_id, d.tenant_id, s.status").
		WithArgs(sigID).
		WillReturnRows(pgxmock.NewRows([]string{"documento_id", "tenant_id", "tenant_id", "status"}).
			AddRow(docID, int64(10), int64(10), "convidado"))
	mock.ExpectRollback()

	mock.ExpectExec("UPDATE assinatura_digital.webhook_events SET erro").
		WithArgs(pgxmock.AnyArg(), int64(2)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	router := chi.NewRouter()
	router.Post("/{provider}", h.ReceberWebhook)

	req := httptest.NewRequest(http.MethodPost, "/intic", bytes.NewReader(body))
	req.Header.Set("X-Signature", signWebhook("segredo", body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnprocessableEntity {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusUnprocessableEntity, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}

// TestReceberWebhook_ReprocessaEventoFalhado confirma que um evento
// previamente registado com processado=false (falhou da primeira vez) é
// reprocessado em vez de ser tratado como duplicado.
func TestReceberWebhook_ReprocessaEventoFalhado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{cfg: webhookTestConfig(), db: mock}

	docID := int64(10)
	tenantID := int64(10)
	payload := map[string]any{
		"event_id":     "evt-retry",
		"event_type":   "signature.canceled",
		"timestamp":    time.Now().UTC(),
		"nonce":        "retry-nonce",
		"tenant_id":    tenantID,
		"documento_id": docID,
	}
	body, _ := json.Marshal(payload)

	// Evento já existia (retry) e ainda não tinha sido processado com sucesso.
	mock.ExpectQuery("INSERT INTO assinatura_digital.webhook_events").
		WithArgs("intic", "evt-retry", "signature.canceled", pgxmock.AnyArg(), pgxmock.AnyArg(), tenantID).
		WillReturnRows(pgxmock.NewRows([]string{"id"}))
	mock.ExpectQuery("SELECT id, processado FROM assinatura_digital.webhook_events").
		WithArgs("intic", "evt-retry").
		WillReturnRows(pgxmock.NewRows([]string{"id", "processado"}).AddRow(int64(3), false))

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT tenant_id, status FROM assinatura_digital.documentos").
		WithArgs(docID).
		WillReturnRows(pgxmock.NewRows([]string{"tenant_id", "status"}).AddRow(tenantID, "pendente"))
	mock.ExpectExec("UPDATE assinatura_digital.documentos").
		WithArgs(docID, tenantID).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))
	mock.ExpectExec("INSERT INTO assinatura_digital.logs").
		WithArgs(pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg()).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectExec("UPDATE assinatura_digital.webhook_events SET processado=TRUE").
		WithArgs(int64(3)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))
	mock.ExpectCommit()

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
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}
