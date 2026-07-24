package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestPaginaVerificacao(t *testing.T) {
	h := &Handler{}
	req := httptest.NewRequest(http.MethodGet, "/verificar-assinatura", nil)
	rr := httptest.NewRecorder()

	h.PaginaVerificacao(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusOK)
	}
	ct := rr.Header().Get("Content-Type")
	if !strings.HasPrefix(ct, "text/html") {
		t.Errorf("Content-Type = %q, want text/html", ct)
	}
	body := rr.Body.String()
	if !strings.Contains(body, "/api/public/assinatura-digital/verificar/") {
		t.Error("página não referencia o endpoint de verificação esperado")
	}
	if !strings.Contains(body, "<html") {
		t.Error("resposta não parece HTML")
	}
}
