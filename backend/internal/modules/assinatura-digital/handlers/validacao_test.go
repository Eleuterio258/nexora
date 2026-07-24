package handlers

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
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

func newAuthedRequest(method, path string, tenantID int64) *http.Request {
	req := httptest.NewRequest(method, path, nil)
	user := &mw.AuthUser{ID: 99, TenantID: tenantID, Tipo: "funcionario", Escopo: "erp"}
	return req.WithContext(context.WithValue(req.Context(), mw.UserKey, user))
}

func TestEvidencias_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockProviderInMemory()
	h := &Handler{db: mock, storage: store}

	pdfData := []byte("%PDF-1.4 fake pdf content")
	pdfHash := sha256.Sum256(pdfData)
	pdfHashHex := hex.EncodeToString(pdfHash[:])
	storageKey := "assinatura-digital/tenant-1/" + pdfHashHex + ".pdf"
	store.Put(context.Background(), storageKey, pdfData, "application/pdf")

	mock.ExpectQuery("SELECT id, tenant_id, titulo, status, hash_sha256, created_at, origem_modulo, origem_id").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"id", "tenant_id", "titulo", "status", "hash_sha256", "created_at", "origem_modulo", "origem_id"}).
			AddRow(int64(10), int64(1), "Contrato", "pendente", pdfHashHex, time.Now(), nil, nil))

	mock.ExpectQuery("SELECT id, nome, email, telefone, tipo, ordem, status").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"id", "nome", "email", "telefone", "tipo", "ordem", "status"}).
			AddRow(int64(20), "Ana Mussa", nil, nil, "assinatura", 1, "convidado"))

	mock.ExpectQuery("SELECT id, storage_key, ficheiro_url, hash_sha256, signatario_id, created_at").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"id", "storage_key", "ficheiro_url", "hash_sha256", "signatario_id", "created_at"}))

	mock.ExpectQuery("SELECT id, signatario_id, acao, detalhes, user_id, ip_address, created_at").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"id", "signatario_id", "acao", "detalhes", "user_id", "ip_address", "created_at"}))

	mock.ExpectQuery("SELECT id, versao_id, hash_verificado, assinaturas, certificado_valido, certificado_motivo, resultado, detalhes, user_id, created_at").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"id", "versao_id", "hash_verificado", "assinaturas", "certificado_valido", "certificado_motivo", "resultado", "detalhes", "user_id", "created_at"}))

	router := chi.NewRouter()
	router.Get("/{id}/evidencias", h.Evidencias)

	req := newAuthedRequest(http.MethodGet, "/10/evidencias", int64(1))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
}

func TestValidacao_DocumentoSemVersao(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockProviderInMemory()
	h := &Handler{db: mock, storage: store}

	pdfData := []byte("%PDF-1.4 fake pdf content")
	pdfHash := sha256.Sum256(pdfData)
	pdfHashHex := hex.EncodeToString(pdfHash[:])
	storageKey := "assinatura-digital/tenant-1/" + pdfHashHex + ".pdf"
	store.Put(context.Background(), storageKey, pdfData, "application/pdf")

	mock.ExpectQuery("SELECT status, storage_key, hash_sha256").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"status", "storage_key", "hash_sha256"}).
			AddRow("pendente", storageKey, pdfHashHex))

	mock.ExpectQuery("SELECT storage_key, hash_sha256").
		WithArgs(int64(10), int64(1)).
		WillReturnError(pgx.ErrNoRows)

	router := chi.NewRouter()
	router.Get("/{id}/validacao", h.Validacao)

	req := newAuthedRequest(http.MethodGet, "/10/validacao", int64(1))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	body := rr.Body.String()
	if !strings.Contains(body, `"resultado":"parcial"`) {
		t.Errorf("esperava resultado parcial, body=%s", body)
	}
}

func TestValidacao_HashNaoBate(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockProviderInMemory()
	h := &Handler{db: mock, storage: store}

	pdfData := []byte("%PDF-1.4 fake pdf content")
	pdfHash := sha256.Sum256(pdfData)
	pdfHashHex := hex.EncodeToString(pdfHash[:])
	storageKey := "assinatura-digital/tenant-1/" + pdfHashHex + ".pdf"
	store.Put(context.Background(), storageKey, pdfData, "application/pdf")

	mock.ExpectQuery("SELECT status, storage_key, hash_sha256").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"status", "storage_key", "hash_sha256"}).
			AddRow("pendente", storageKey, strings.Repeat("0", 64)))

	router := chi.NewRouter()
	router.Get("/{id}/validacao", h.Validacao)

	req := newAuthedRequest(http.MethodGet, "/10/validacao", int64(1))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	body := rr.Body.String()
	if !strings.Contains(body, `"resultado":"invalido"`) {
		t.Errorf("esperava resultado invalido, body=%s", body)
	}
}

func TestRevalidar_RegistaValidacao(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	store := newMockProviderInMemory()
	h := &Handler{db: mock, storage: store}

	pdfData := []byte("%PDF-1.4 fake pdf content")
	pdfHash := sha256.Sum256(pdfData)
	pdfHashHex := hex.EncodeToString(pdfHash[:])
	storageKey := "assinatura-digital/tenant-1/" + pdfHashHex + ".pdf"
	store.Put(context.Background(), storageKey, pdfData, "application/pdf")

	mock.ExpectQuery("SELECT status, storage_key, hash_sha256").
		WithArgs(int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"status", "storage_key", "hash_sha256"}).
			AddRow("pendente", storageKey, pdfHashHex))

	mock.ExpectQuery("SELECT storage_key, hash_sha256").
		WithArgs(int64(10), int64(1)).
		WillReturnError(pgx.ErrNoRows)

	mock.ExpectQuery("SELECT id FROM assinatura_digital.versoes_assinadas").
		WithArgs(int64(10), int64(1)).
		WillReturnError(pgx.ErrNoRows)

	mock.ExpectExec("INSERT INTO assinatura_digital.validacoes").
		WithArgs(
			pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(),
			pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(),
			pgxmock.AnyArg(), pgxmock.AnyArg(), pgxmock.AnyArg(),
		).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	router := chi.NewRouter()
	router.Post("/{id}/revalidar", h.Revalidar)

	req := newAuthedRequest(http.MethodPost, "/10/revalidar", int64(1))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
}
