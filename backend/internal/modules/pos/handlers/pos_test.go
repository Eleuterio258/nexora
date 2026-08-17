package handlers

import (
	"context"
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

func comUser(r *http.Request, u *mw.AuthUser) *http.Request {
	return r.WithContext(context.WithValue(r.Context(), mw.UserKey, u))
}

func TestObterTerminal_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 1, TenantID: 100}
	mock.ExpectQuery("SELECT id, codigo, nome, warehouse_id, caixa_id, user_id, activo, created_at, updated_at, deleted_at").
		WithArgs("5", int64(100)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "codigo", "nome", "warehouse_id", "caixa_id", "user_id", "activo", "created_at", "updated_at", "deleted_at",
		}).AddRow(int64(5), "CAIXA-01", "Caixa Principal", (*int64)(nil), (*int64)(nil), (*int64)(nil), true, time.Now(), time.Now(), (*time.Time)(nil)))

	req := httptest.NewRequest(http.MethodGet, "/terminais/5", nil)
	req = comUser(req, user)

	r := chi.NewRouter()
	r.Get("/terminais/{id}", h.ObterTerminal)
	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestObterTerminal_NaoEncontrado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 1, TenantID: 100}
	mock.ExpectQuery("SELECT id, codigo, nome, warehouse_id, caixa_id, user_id, activo, created_at, updated_at, deleted_at").
		WithArgs("5", int64(100)).
		WillReturnError(pgx.ErrNoRows)

	req := httptest.NewRequest(http.MethodGet, "/terminais/5", nil)
	req = comUser(req, user)

	r := chi.NewRouter()
	r.Get("/terminais/{id}", h.ObterTerminal)
	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestActualizarTerminal_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 1, TenantID: 100}
	mock.ExpectExec("UPDATE pos_terminals").
		WithArgs("Caixa Principal Loja 2", pgxmock.AnyArg(), pgxmock.AnyArg(), "5", int64(100)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	req := httptest.NewRequest(http.MethodPut, "/terminais/5", strings.NewReader(`{"nome":"Caixa Principal Loja 2","warehouse_id":3,"caixa_id":2}`))
	req = comUser(req, user)

	r := chi.NewRouter()
	r.Put("/terminais/{id}", h.ActualizarTerminal)
	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNoContent, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestArquivarTerminal_BloqueiaComSessoes(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 1, TenantID: 100}
	mock.ExpectQuery("SELECT EXISTS").
		WithArgs("5").
		WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(true))

	req := httptest.NewRequest(http.MethodDelete, "/terminais/5", nil)
	req = comUser(req, user)

	r := chi.NewRouter()
	r.Delete("/terminais/{id}", h.ArquivarTerminal)
	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if rr.Code != http.StatusConflict {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusConflict, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestObterSessaoPorID_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 10, TenantID: 100}
	openedAt := time.Now()
	mock.ExpectQuery("SELECT s.id, s.terminal_id, COALESCE").
		WithArgs("7", int64(100)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "terminal_id", "terminal_nome", "user_id", "operador_nome",
			"funcionario_id", "opened_at", "closed_at", "opening_amount", "closing_amount", "status", "created_at",
		}).AddRow(int64(7), int64(5), "Caixa Principal", int64(10), "Maria Santos", (*int64)(nil), openedAt, (*time.Time)(nil), 1000.0, (*float64)(nil), "aberta", openedAt))

	req := httptest.NewRequest(http.MethodGet, "/sessoes/7", nil)
	req = comUser(req, user)

	r := chi.NewRouter()
	r.Get("/sessoes/{id}", h.ObterSessaoPorID)
	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestCancelarVenda_MotivoObrigatorio(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	user := &mw.AuthUser{ID: 10, TenantID: 100}

	req := httptest.NewRequest(http.MethodPost, "/sales/9/cancelar", strings.NewReader(`{}`))
	req = comUser(req, user)

	r := chi.NewRouter()
	r.Post("/sales/{id}/cancelar", h.CancelarVenda)
	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
}
