package handlers

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/pashagolub/pgxmock/v4"

	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

// mockSignaturePort é uma implementação fake de contracts.SignaturePort para testes.
type mockSignaturePort struct {
	create func(ctx context.Context, r contracts.SignatureDocumentRequest) (int64, error)
}

func (m *mockSignaturePort) CreateForSigning(ctx context.Context, r contracts.SignatureDocumentRequest) (int64, error) {
	if m.create != nil {
		return m.create(ctx, r)
	}
	return 999, nil
}

// mockStorageProvider é uma implementação mínima de storage.Provider.
type mockStorageProvider struct {
	data map[string][]byte
}

func newMockStorageProvider() *mockStorageProvider {
	return &mockStorageProvider{data: map[string][]byte{}}
}

func (m *mockStorageProvider) Put(ctx context.Context, key string, data []byte, contentType string) (string, error) {
	m.data[key] = data
	return "mock://" + key, nil
}

func (m *mockStorageProvider) Get(ctx context.Context, key string) (io.ReadCloser, int64, error) {
	data, ok := m.data[key]
	if !ok {
		return nil, 0, errStorageNotFound{}
	}
	return io.NopCloser(bytes.NewReader(data)), int64(len(data)), nil
}

func (m *mockStorageProvider) GetURL(ctx context.Context, key string) (string, error) {
	return "mock://" + key, nil
}

func (m *mockStorageProvider) Delete(ctx context.Context, key string) error {
	delete(m.data, key)
	return nil
}

func (m *mockStorageProvider) Exists(ctx context.Context, key string) (bool, error) {
	_, ok := m.data[key]
	return ok, nil
}

type errStorageNotFound struct{}

func (errStorageNotFound) Error() string { return "not found" }

func newAuthedFaturacaoRequest(method, path string, tenantID int64) *http.Request {
	req := httptest.NewRequest(method, path, nil)
	user := &mw.AuthUser{ID: 99, TenantID: tenantID, Tipo: "funcionario", Escopo: "erp"}
	return req.WithContext(context.WithValue(req.Context(), mw.UserKey, user))
}

func TestEnviarFaturaParaAssinatura_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockStorageProvider()
	pdfData := []byte("%PDF-1.4 fatura pdf")
	storageKey := invoicePDFKey(1, 10)
	store.Put(context.Background(), storageKey, pdfData, "application/pdf")

	sig := &mockSignaturePort{}
	h := New(mock, nil, store, sig)

	mock.ExpectQuery("SELECT COALESCE").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"pdf_storage_key", "ficheiro_url", "nome", "email"}).
			AddRow(storageKey, "https://exemplo.mz/fatura.pdf", "Cliente ABC", "cliente@exemplo.co.mz"))

	mock.ExpectExec("UPDATE faturacao.invoices").
		WithArgs(int64(999), int64(10), int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	router := chi.NewRouter()
	router.Post("/{id}/enviar-para-assinatura", h.EnviarFaturaParaAssinatura)

	req := newAuthedFaturacaoRequest(http.MethodPost, "/10/enviar-para-assinatura", int64(1))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusCreated {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusCreated, rr.Body.String())
	}
}

func TestEnviarFaturaParaAssinatura_SemPDF(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockStorageProvider()
	sig := &mockSignaturePort{}
	h := New(mock, nil, store, sig)

	mock.ExpectQuery("SELECT COALESCE").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"pdf_storage_key", "ficheiro_url", "nome", "email"}).
			AddRow("", "", "Cliente ABC", "cliente@exemplo.co.mz"))

	router := chi.NewRouter()
	router.Post("/{id}/enviar-para-assinatura", h.EnviarFaturaParaAssinatura)

	req := newAuthedFaturacaoRequest(http.MethodPost, "/10/enviar-para-assinatura", int64(1))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}
