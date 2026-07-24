package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/pashagolub/pgxmock/v4"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

// mockConviteRows monta a linha devolvida por obterConviteValido com os
// campos de OTP indicados; os restantes campos (documento, signatário) usam
// valores fixos suficientes para os testes de ValidarOTP.
func mockConviteRows(otpHash *string, otpExpiraEm *time.Time, otpTentativas int, otpConfirmadoEm *time.Time) *pgxmock.Rows {
	expira := time.Now().Add(24 * time.Hour)
	return pgxmock.NewRows([]string{
		"c.id", "c.documento_id", "c.signatario_id", "c.tenant_id", "c.expira_em", "c.usado_em",
		"c.otp_hash", "c.otp_expira_em", "c.otp_tentativas", "c.otp_confirmado_em",
		"s.nome", "s.email", "s.telefone", "s.ordem", "s.tipo", "s.status", "d.status",
	}).AddRow(int64(1), int64(10), int64(20), int64(1), expira, nil,
		otpHash, otpExpiraEm, otpTentativas, otpConfirmadoEm,
		"Ana Mussa", nil, nil, 1, "assinatura", "convidado", "pendente")
}

func TestValidarOTP_CodigoCorreto(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-ok"
	tokenHash := mw.HashToken(token)
	hash, err := bcrypt.GenerateFromPassword([]byte("123456"), bcrypt.DefaultCost)
	if err != nil {
		t.Fatal(err)
	}
	hashStr := string(hash)
	expira := time.Now().Add(10 * time.Minute)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(mockConviteRows(&hashStr, &expira, 0, nil))

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT otp_hash, otp_expira_em, otp_tentativas").
		WithArgs(int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"otp_hash", "otp_expira_em", "otp_tentativas"}).
			AddRow(&hashStr, &expira, 0))
	mock.ExpectExec("UPDATE assinatura_digital.convites SET otp_confirmado_em").
		WithArgs(int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))
	mock.ExpectCommit()

	router := chi.NewRouter()
	router.Post("/{token}/otp/validar", h.ValidarOTP)

	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/validar", strings.NewReader(`{"codigo":"123456"}`))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d, body=%s", rr.Code, http.StatusOK, rr.Body.String())
	}
	if !strings.Contains(rr.Body.String(), `"confirmado":true`) {
		t.Errorf("esperava confirmado=true, body=%s", rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}

func TestValidarOTP_CodigoErrado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-errado"
	tokenHash := mw.HashToken(token)
	hash, _ := bcrypt.GenerateFromPassword([]byte("123456"), bcrypt.DefaultCost)
	hashStr := string(hash)
	expira := time.Now().Add(10 * time.Minute)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(mockConviteRows(&hashStr, &expira, 0, nil))

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT otp_hash, otp_expira_em, otp_tentativas").
		WithArgs(int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"otp_hash", "otp_expira_em", "otp_tentativas"}).
			AddRow(&hashStr, &expira, 0))
	mock.ExpectExec("UPDATE assinatura_digital.convites SET otp_tentativas").
		WithArgs(int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))
	mock.ExpectCommit()

	router := chi.NewRouter()
	router.Post("/{token}/otp/validar", h.ValidarOTP)

	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/validar", strings.NewReader(`{"codigo":"000000"}`))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d, body=%s", rr.Code, http.StatusUnauthorized, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas (o incremento de tentativas deveria ter corrido): %v", err)
	}
}

func TestValidarOTP_LimiteTentativasExcedido(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-esgotado"
	tokenHash := mw.HashToken(token)
	hash, _ := bcrypt.GenerateFromPassword([]byte("123456"), bcrypt.DefaultCost)
	hashStr := string(hash)
	expira := time.Now().Add(10 * time.Minute)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(mockConviteRows(&hashStr, &expira, otpMaxTentativas, nil))

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT otp_hash, otp_expira_em, otp_tentativas").
		WithArgs(int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"otp_hash", "otp_expira_em", "otp_tentativas"}).
			AddRow(&hashStr, &expira, otpMaxTentativas))
	mock.ExpectRollback()

	router := chi.NewRouter()
	router.Post("/{token}/otp/validar", h.ValidarOTP)

	// Mesmo com o código correcto, o limite de tentativas já esgotado tem de
	// bloquear — sem isto o limite não protegeria contra força bruta.
	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/validar", strings.NewReader(`{"codigo":"123456"}`))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusTooManyRequests {
		t.Fatalf("status = %d, want %d, body=%s", rr.Code, http.StatusTooManyRequests, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}

func TestValidarOTP_CodigoExpirado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-expirado"
	tokenHash := mw.HashToken(token)
	hash, _ := bcrypt.GenerateFromPassword([]byte("123456"), bcrypt.DefaultCost)
	hashStr := string(hash)
	expirado := time.Now().Add(-1 * time.Minute)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(mockConviteRows(&hashStr, &expirado, 0, nil))

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT otp_hash, otp_expira_em, otp_tentativas").
		WithArgs(int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"otp_hash", "otp_expira_em", "otp_tentativas"}).
			AddRow(&hashStr, &expirado, 0))
	mock.ExpectRollback()

	router := chi.NewRouter()
	router.Post("/{token}/otp/validar", h.ValidarOTP)

	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/validar", strings.NewReader(`{"codigo":"123456"}`))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}

func TestValidarOTP_NenhumCodigoSolicitado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := &Handler{db: mock}
	token := "otp-nunca-pedido"
	tokenHash := mw.HashToken(token)

	mock.ExpectQuery("FROM assinatura_digital.convites").
		WithArgs(tokenHash).
		WillReturnRows(mockConviteRows(nil, nil, 0, nil))

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT otp_hash, otp_expira_em, otp_tentativas").
		WithArgs(int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"otp_hash", "otp_expira_em", "otp_tentativas"}).
			AddRow(nil, nil, 0))
	mock.ExpectRollback()

	router := chi.NewRouter()
	router.Post("/{token}/otp/validar", h.ValidarOTP)

	req := httptest.NewRequest(http.MethodPost, "/"+token+"/otp/validar", strings.NewReader(`{"codigo":"123456"}`))
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d, body=%s", rr.Code, http.StatusBadRequest, rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("expectativas não cumpridas: %v", err)
	}
}
