package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/pashagolub/pgxmock/v4"
)

func TestRequireSuperadminIPAllowlist_AllowWhenEmpty(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery(`SELECT COUNT\(\*\) FROM auth\.superadmin_ip_allowlist WHERE ativo = true`).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(int64(0)))

	handler := RequireSuperadminIPAllowlist(mock)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req = req.WithContext(context.WithValue(req.Context(), UserKey, &AuthUser{ID: 1, Tipo: "superadmin"}))
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestRequireSuperadminIPAllowlist_BlockIPNotInList(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery(`SELECT COUNT\(\*\) FROM auth\.superadmin_ip_allowlist WHERE ativo = true`).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(int64(1)))
	mock.ExpectQuery(`SELECT ip_cidr::text FROM auth\.superadmin_ip_allowlist WHERE ativo = true`).
		WillReturnRows(pgxmock.NewRows([]string{"ip_cidr"}).AddRow("10.0.0.0/8"))

	handler := RequireSuperadminIPAllowlist(mock)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "192.168.1.1:1234"
	req = req.WithContext(context.WithValue(req.Context(), UserKey, &AuthUser{ID: 1, Tipo: "superadmin"}))
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusForbidden, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestRequireSuperadminIPAllowlist_AllowIPInCIDR(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery(`SELECT COUNT\(\*\) FROM auth\.superadmin_ip_allowlist WHERE ativo = true`).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(int64(1)))
	mock.ExpectQuery(`SELECT ip_cidr::text FROM auth\.superadmin_ip_allowlist WHERE ativo = true`).
		WillReturnRows(pgxmock.NewRows([]string{"ip_cidr"}).AddRow("10.0.0.0/8"))

	handler := RequireSuperadminIPAllowlist(mock)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "10.1.2.3:1234"
	req = req.WithContext(context.WithValue(req.Context(), UserKey, &AuthUser{ID: 1, Tipo: "superadmin"}))
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}

func TestRequireSuperadminReauth_BlockWhenExpired(t *testing.T) {
	handler := RequireSuperadminReauth(15 * time.Minute)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req = req.WithContext(context.WithValue(req.Context(), UserKey, &AuthUser{
		ID:       1,
		Tipo:     "superadmin",
		ReauthAt: time.Now().Add(-20 * time.Minute),
	}))
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusForbidden {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusForbidden, rr.Body.String())
	}
}

func TestRequireSuperadminReauth_AllowWhenRecent(t *testing.T) {
	handler := RequireSuperadminReauth(15 * time.Minute)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req = req.WithContext(context.WithValue(req.Context(), UserKey, &AuthUser{
		ID:       1,
		Tipo:     "superadmin",
		ReauthAt: time.Now().Add(-5 * time.Minute),
	}))
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
}
