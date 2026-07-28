package handlers

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/pashagolub/pgxmock/v4"

	mw "nexora/internal/middleware"
)

func newAuthedEmpresasRequest(method, path string, tenantID int64) *http.Request {
	req := httptest.NewRequest(method, path, nil)
	user := &mw.AuthUser{ID: 99, TenantID: tenantID, Tipo: "funcionario", Escopo: "erp"}
	return req.WithContext(context.WithValue(req.Context(), mw.UserKey, user))
}

func TestObterEmpresa_CrossTenant(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}

	mock.ExpectQuery("SELECT id FROM empresas.companies WHERE id = \\$1 AND tenant_id = \\$2").
		WithArgs("7", int64(5)).
		WillReturnRows(pgxmock.NewRows([]string{"id"}))

	router := chi.NewRouter()
	router.Get("/{id}", h.ObterEmpresa)

	req := newAuthedEmpresasRequest(http.MethodGet, "/7", int64(5))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
}

func TestActualizarEmpresa_CrossTenant(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}

	mock.ExpectExec("UPDATE empresas.companies SET").
		WithArgs(
			nil, nil, nil, nil, nil,
			"7", int64(5), false,
		).
		WillReturnResult(pgxmock.NewResult("UPDATE", 0))

	router := chi.NewRouter()
	router.Put("/{id}", h.ActualizarEmpresa)

	req := newAuthedEmpresasRequest(http.MethodPut, "/7", int64(5))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
}
