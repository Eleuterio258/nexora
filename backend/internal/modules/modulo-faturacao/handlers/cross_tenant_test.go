package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/pashagolub/pgxmock/v4"
)

func TestAdicionarItemOrcamento_CrossTenant(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := New(mock, nil, nil, nil, nil, nil, nil)

	// O orçamento #10 existe mas pertence a outro tenant.
	mock.ExpectQuery("SELECT 1 FROM sales_quotes WHERE id=\\$1 AND tenant_id=\\$2").
		WithArgs("10", int64(5)).
		WillReturnRows(pgxmock.NewRows([]string{"?column?"}))

	router := chi.NewRouter()
	router.Post("/{id}/itens", h.AdicionarItemOrcamento)

	body, _ := json.Marshal(map[string]any{
		"quantidade":     1,
		"preco_unitario": 100,
	})
	req := newAuthedFaturacaoRequest(http.MethodPost, "/10/itens", int64(5))
	req = httptest.NewRequest(http.MethodPost, "/10/itens", strings.NewReader(string(body)))
	req = req.WithContext(newAuthedFaturacaoRequest(http.MethodPost, "/10/itens", int64(5)).Context())
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
}

func TestCriarRecibo_CrossTenant(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	h := New(mock, nil, nil, nil, nil, nil, nil)

	// A fatura #20 existe mas pertence a outro tenant.
	mock.ExpectQuery("SELECT 1 FROM invoices WHERE id=\\$1 AND tenant_id=\\$2").
		WithArgs(int64(20), int64(5)).
		WillReturnRows(pgxmock.NewRows([]string{"?column?"}))

	body, _ := json.Marshal(map[string]any{
		"invoice_id": 20,
		"valor":      100,
	})
	req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(string(body)))
	req = req.WithContext(newAuthedFaturacaoRequest(http.MethodPost, "/", int64(5)).Context())
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	h.CriarRecibo(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d, body=%s", rr.Code, http.StatusNotFound, rr.Body.String())
	}
}
