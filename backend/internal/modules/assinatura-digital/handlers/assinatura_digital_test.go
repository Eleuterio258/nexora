package handlers

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/pashagolub/pgxmock/v4"

	mw "nexora/internal/middleware"
)

func comUser(r *http.Request, u *mw.AuthUser) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), mw.UserKey, u))
}

func TestVerificarOrdem_PermiteQuandoNaoHaPendentesAnteriores(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	mock.ExpectQuery("SELECT COUNT").
		WithArgs(int64(10), 2).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(0))

	ok, err := h.verificarOrdem(context.Background(), 10, 2)
	if err != nil {
		t.Fatalf("verificarOrdem: %v", err)
	}
	if !ok {
		t.Error("esperava ordem OK quando não há signatários anteriores pendentes")
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestVerificarOrdem_BloqueiaComPendentesAnteriores(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	mock.ExpectQuery("SELECT COUNT").
		WithArgs(int64(10), 2).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(1))

	ok, err := h.verificarOrdem(context.Background(), 10, 2)
	if err != nil {
		t.Fatalf("verificarOrdem: %v", err)
	}
	if ok {
		t.Error("esperava ordem bloqueada quando existe signatário anterior ainda não assinado")
	}
}

// TestAssinarDocumento_RejeitaSignatarioNaoVinculado confirma que um
// utilizador autenticado não consegue assinar por um signatário que não
// esteja vinculado à sua própria conta (signatarios.user_id) — fecha a
// lacuna histórica "um gestor pode registar assinatura por terceiro".
func TestAssinarDocumento_RejeitaSignatarioNaoVinculado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 1, TenantID: 100}
	outroUserID := int64(999)

	mock.ExpectQuery("SELECT status FROM assinatura_digital.documentos").
		WithArgs(int64(5), int64(100)).
		WillReturnRows(pgxmock.NewRows([]string{"status"}).AddRow("pendente"))

	mock.ExpectQuery("SELECT user_id, ordem FROM assinatura_digital.signatarios").
		WithArgs(int64(45), int64(5), int64(100)).
		WillReturnRows(pgxmock.NewRows([]string{"user_id", "ordem"}).AddRow(&outroUserID, 1))

	req := httptest.NewRequest(http.MethodPost, "/documentos/5/assinar", strings.NewReader(`{"signatario_id":45}`))
	req = comUser(req, user)

	router := chi.NewRouter()
	router.Post("/documentos/{id}/assinar", h.AssinarDocumento)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusForbidden, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

// TestAdicionarSignatario_RejeitaUserIDDeOutroTenant confirma que não é
// possível vincular um signatário a um utilizador de outro tenant.
func TestAdicionarSignatario_RejeitaUserIDDeOutroTenant(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 1, TenantID: 100}

	mock.ExpectQuery("SELECT status FROM assinatura_digital.documentos").
		WithArgs(int64(5), int64(100)).
		WillReturnRows(pgxmock.NewRows([]string{"status"}).AddRow("rascunho"))

	mock.ExpectQuery("SELECT EXISTS").
		WithArgs(int64(999), int64(100)).
		WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(false))

	req := httptest.NewRequest(http.MethodPost, "/documentos/5/signatarios", strings.NewReader(`{"nome":"Ana Mussa","user_id":999}`))
	req = comUser(req, user)

	router := chi.NewRouter()
	router.Post("/documentos/{id}/signatarios", h.AdicionarSignatario)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}
