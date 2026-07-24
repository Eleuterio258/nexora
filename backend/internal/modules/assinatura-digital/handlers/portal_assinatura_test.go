package handlers

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/pashagolub/pgxmock/v4"

	mw "nexora/internal/middleware"
)

// mockProviderInMemory é uma implementação mínima de storage.Provider para testes.
type mockProviderInMemory struct {
	data map[string][]byte
}

func newMockProviderInMemory() *mockProviderInMemory {
	return &mockProviderInMemory{data: map[string][]byte{}}
}

func (m *mockProviderInMemory) Put(ctx context.Context, key string, data []byte, contentType string) (string, error) {
	m.data[key] = data
	return "mock://" + key, nil
}

func (m *mockProviderInMemory) Get(ctx context.Context, key string) (io.ReadCloser, int64, error) {
	data, ok := m.data[key]
	if !ok {
		return nil, 0, errStorageNotFound{}
	}
	return io.NopCloser(bytes.NewReader(data)), int64(len(data)), nil
}

func (m *mockProviderInMemory) GetURL(ctx context.Context, key string) (string, error) {
	return "mock://" + key, nil
}

func (m *mockProviderInMemory) Delete(ctx context.Context, key string) error {
	delete(m.data, key)
	return nil
}

func (m *mockProviderInMemory) Exists(ctx context.Context, key string) (bool, error) {
	_, ok := m.data[key]
	return ok, nil
}

type errStorageNotFound struct{}

func (errStorageNotFound) Error() string { return "not found" }

func TestPaginaAssinatura_ServeHTMLComToken(t *testing.T) {
	h := &Handler{}
	router := chi.NewRouter()
	router.Get("/assinar/{token}", h.PaginaAssinatura)

	token := "token-de-teste-123"
	req := httptest.NewRequest(http.MethodGet, "/assinar/"+token, nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	ct := rr.Header().Get("Content-Type")
	if !strings.Contains(ct, "text/html") {
		t.Errorf("Content-Type = %q, esperava text/html", ct)
	}
	body := rr.Body.String()
	if !strings.Contains(body, "const TOKEN = '"+token+"';") {
		t.Error("o token não foi injetado corretamente no HTML")
	}
	if !strings.Contains(body, "Assinar documento") {
		t.Error("HTML não contém o título esperado")
	}
}

func TestPaginaAssinatura_TokenVazio_Devolve404(t *testing.T) {
	h := &Handler{}
	router := chi.NewRouter()
	router.Get("/assinar/{token}", h.PaginaAssinatura)

	req := httptest.NewRequest(http.MethodGet, "/assinar/", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d", rr.Code, http.StatusNotFound)
	}
}

func TestPreviewDocumentoConvite_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockProviderInMemory()
	h := &Handler{db: mock, storage: store}

	token := "token-valido"
	tokenHash := mw.HashToken(token)
	pdfData := []byte("%PDF-1.4 fake pdf content")
	pdfHash := sha256.Sum256(pdfData)
	pdfHashHex := hex.EncodeToString(pdfHash[:])
	storageKey := "assinatura-digital/tenant-1/" + pdfHashHex + ".pdf"
	store.Put(context.Background(), storageKey, pdfData, "application/pdf")

	expira := time.Now().Add(24 * time.Hour)
	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(pgxmock.NewRows([]string{
			"c.id", "c.documento_id", "c.signatario_id", "c.tenant_id", "c.expira_em", "c.usado_em",
			"c.otp_hash", "c.otp_expira_em", "c.otp_tentativas", "c.otp_confirmado_em",
			"s.nome", "s.email", "s.telefone", "s.ordem", "s.tipo", "s.status", "d.status",
		}).AddRow(int64(1), int64(10), int64(20), int64(1), expira, nil, nil, nil, 0, nil, "Ana Mussa", nil, nil, 1, "assinatura", "convidado", "pendente"))

	mock.ExpectQuery("SELECT storage_key, hash_sha256").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"storage_key", "hash_sha256"}).AddRow(storageKey, pdfHashHex))

	router := chi.NewRouter()
	router.Get("/{token}/preview", h.PreviewDocumentoConvite)

	req := httptest.NewRequest(http.MethodGet, "/"+token+"/preview", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	ct := rr.Header().Get("Content-Type")
	if ct != "application/pdf" {
		t.Errorf("Content-Type = %q, want application/pdf", ct)
	}
	cd := rr.Header().Get("Content-Disposition")
	if !strings.HasPrefix(cd, "inline") {
		t.Errorf("Content-Disposition = %q, esperava inline", cd)
	}
	if !bytes.Equal(rr.Body.Bytes(), pdfData) {
		t.Error("corpo da resposta não corresponde ao PDF esperado")
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestPreviewDocumentoConvite_ConviteInvalido(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "token-invalido"
	tokenHash := mw.HashToken(token)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnError(pgx.ErrNoRows)

	router := chi.NewRouter()
	router.Get("/{token}/preview", h.PreviewDocumentoConvite)

	req := httptest.NewRequest(http.MethodGet, "/"+token+"/preview", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
}

func TestPreviewDocumentoConvite_DocumentoNaoPendente(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "token-ja-assinado"
	tokenHash := mw.HashToken(token)
	expira := time.Now().Add(24 * time.Hour)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(pgxmock.NewRows([]string{
			"c.id", "c.documento_id", "c.signatario_id", "c.tenant_id", "c.expira_em", "c.usado_em",
			"c.otp_hash", "c.otp_expira_em", "c.otp_tentativas", "c.otp_confirmado_em",
			"s.nome", "s.email", "s.telefone", "s.ordem", "s.tipo", "s.status", "d.status",
		}).AddRow(int64(1), int64(10), int64(20), int64(1), expira, nil, nil, nil, 0, nil, "Ana Mussa", nil, nil, 1, "assinatura", "assinado", "assinado"))

	router := chi.NewRouter()
	router.Get("/{token}/preview", h.PreviewDocumentoConvite)

	req := httptest.NewRequest(http.MethodGet, "/"+token+"/preview", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusConflict {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusConflict, rr.Body.String())
	}
}

func TestPreviewDocumentoConvite_HashNaoBate(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockProviderInMemory()
	h := &Handler{db: mock, storage: store}

	token := "token-hash-errado"
	tokenHash := mw.HashToken(token)
	pdfData := []byte("%PDF-1.4 fake pdf content")
	storageKey := "assinatura-digital/tenant-1/doc.pdf"
	store.Put(context.Background(), storageKey, pdfData, "application/pdf")

	expira := time.Now().Add(24 * time.Hour)
	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(pgxmock.NewRows([]string{
			"c.id", "c.documento_id", "c.signatario_id", "c.tenant_id", "c.expira_em", "c.usado_em",
			"c.otp_hash", "c.otp_expira_em", "c.otp_tentativas", "c.otp_confirmado_em",
			"s.nome", "s.email", "s.telefone", "s.ordem", "s.tipo", "s.status", "d.status",
		}).AddRow(int64(1), int64(10), int64(20), int64(1), expira, nil, nil, nil, 0, nil, "Ana Mussa", nil, nil, 1, "assinatura", "convidado", "pendente"))

	mock.ExpectQuery("SELECT storage_key, hash_sha256").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"storage_key", "hash_sha256"}).AddRow(storageKey, strings.Repeat("0", 64)))

	router := chi.NewRouter()
	router.Get("/{token}/preview", h.PreviewDocumentoConvite)

	req := httptest.NewRequest(http.MethodGet, "/"+token+"/preview", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusConflict {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusConflict, rr.Body.String())
	}
}


func TestEnviarOTP_CanalEmail(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-email"
	tokenHash := mw.HashToken(token)
	email := "ana@example.co.mz"
	expira := time.Now().Add(24 * time.Hour)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(pgxmock.NewRows([]string{
			"c.id", "c.documento_id", "c.signatario_id", "c.tenant_id", "c.expira_em", "c.usado_em",
			"c.otp_hash", "c.otp_expira_em", "c.otp_tentativas", "c.otp_confirmado_em",
			"s.nome", "s.email", "s.telefone", "s.ordem", "s.tipo", "s.status", "d.status",
		}).AddRow(int64(1), int64(10), int64(20), int64(1), expira, nil, nil, nil, 0, nil, "Ana Mussa", &email, nil, 1, "assinatura", "convidado", "pendente"))

	mock.ExpectExec("UPDATE assinatura_digital.convites").
		WithArgs(pgxmock.AnyArg(), otpValidadeMinutos, int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	router := chi.NewRouter()
	router.Post("/{token}/otp/enviar", h.EnviarOTP)

	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/enviar", strings.NewReader(`{"canal":"email"}`))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if !strings.Contains(rr.Body.String(), `"canal":"email"`) {
		t.Errorf("resposta não indica canal email: %s", rr.Body.String())
	}
}

func TestEnviarOTP_CanalSMS(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-sms"
	tokenHash := mw.HashToken(token)
	telefone := "+258840000000"
	expira := time.Now().Add(24 * time.Hour)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(pgxmock.NewRows([]string{
			"c.id", "c.documento_id", "c.signatario_id", "c.tenant_id", "c.expira_em", "c.usado_em",
			"c.otp_hash", "c.otp_expira_em", "c.otp_tentativas", "c.otp_confirmado_em",
			"s.nome", "s.email", "s.telefone", "s.ordem", "s.tipo", "s.status", "d.status",
		}).AddRow(int64(1), int64(10), int64(20), int64(1), expira, nil, nil, nil, 0, nil, "Ana Mussa", nil, &telefone, 1, "assinatura", "convidado", "pendente"))

	mock.ExpectExec("UPDATE assinatura_digital.convites").
		WithArgs(pgxmock.AnyArg(), otpValidadeMinutos, int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	router := chi.NewRouter()
	router.Post("/{token}/otp/enviar", h.EnviarOTP)

	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/enviar", strings.NewReader(`{"canal":"sms"}`))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if !strings.Contains(rr.Body.String(), `"canal":"sms"`) {
		t.Errorf("resposta não indica canal sms: %s", rr.Body.String())
	}
}

func TestEnviarOTP_SemEmailNemTelefone(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-sem-contato"
	tokenHash := mw.HashToken(token)
	expira := time.Now().Add(24 * time.Hour)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(pgxmock.NewRows([]string{
			"c.id", "c.documento_id", "c.signatario_id", "c.tenant_id", "c.expira_em", "c.usado_em",
			"c.otp_hash", "c.otp_expira_em", "c.otp_tentativas", "c.otp_confirmado_em",
			"s.nome", "s.email", "s.telefone", "s.ordem", "s.tipo", "s.status", "d.status",
		}).AddRow(int64(1), int64(10), int64(20), int64(1), expira, nil, nil, nil, 0, nil, "Ana Mussa", nil, nil, 1, "assinatura", "convidado", "pendente"))

	router := chi.NewRouter()
	router.Post("/{token}/otp/enviar", h.EnviarOTP)

	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/enviar", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}
