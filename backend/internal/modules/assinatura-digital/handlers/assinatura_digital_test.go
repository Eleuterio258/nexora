package handlers

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
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

// TestObterDocumento_IsolamentoEntreTenants confirma que um utilizador do
// tenant B não consegue obter um documento do tenant A só por adivinhar o
// id (IDOR) — a query usa sempre o tenant_id do utilizador autenticado, não
// um valor vindo do pedido, e um documento de outro tenant deve resultar em
// 404 (não em 403 nem em dados parciais, para não confirmar a existência do
// recurso a um tenant que não devia sequer saber que ele existe).
func TestObterDocumento_IsolamentoEntreTenants(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	h := &Handler{db: mock}

	// O documento 10 pertence ao tenant 1; o pedido vem autenticado no
	// tenant 2 — a query filtra por (id=10 AND tenant_id=2), que nenhuma
	// linha real satisfaria, tal como pgx.ErrNoRows simula aqui.
	atacante := &mw.AuthUser{ID: 1, TenantID: 2}

	mock.ExpectQuery("SELECT id, titulo, descricao, status, ficheiro_url, hash_sha256").
		WithArgs(int64(10), int64(2)).
		WillReturnError(pgx.ErrNoRows)

	req := httptest.NewRequest(http.MethodGet, "/documentos/10", nil)
	req = comUser(req, atacante)

	router := chi.NewRouter()
	router.Get("/documentos/{id}", h.ObterDocumento)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
	if strings.Contains(rr.Body.String(), "titulo") {
		t.Errorf("resposta não deveria expor nenhum dado do documento de outro tenant: %s", rr.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Error(err)
	}
}
