package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/pashagolub/pgxmock/v4"
)

func TestVerificarPorHash_HashInvalido(t *testing.T) {
	h := &Handler{}
	router := chi.NewRouter()
	router.Get("/verificar/{hash}", h.VerificarPorHash)

	req := httptest.NewRequest(http.MethodGet, "/verificar/nao-e-um-hash", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d", rr.Code, http.StatusBadRequest)
	}
}

func TestVerificarPorHash_NaoEncontrado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	hash := strings.Repeat("a", 64)

	mock.ExpectQuery("FROM assinatura_digital.versoes_assinadas").
		WithArgs(hash).
		WillReturnError(pgx.ErrNoRows)
	mock.ExpectQuery("SELECT id, titulo, status, created_at FROM assinatura_digital.documentos").
		WithArgs(hash).
		WillReturnError(pgx.ErrNoRows)

	router := chi.NewRouter()
	router.Get("/verificar/{hash}", h.VerificarPorHash)
	req := httptest.NewRequest(http.MethodGet, "/verificar/"+hash, nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}
