package handlers

import (
	_ "embed"
	"net/http"
)

//go:embed static/verificar.html
var paginaVerificacaoHTML []byte

// PaginaVerificacao serve uma página HTML autocontida (sem dependências
// externas) que consome a API pública GET /verificar/{hash} para que uma
// pessoa sem conhecimentos técnicos consiga confirmar uma assinatura sem
// precisar de Postman/curl.
// GET /verificar-assinatura
func (h *Handler) PaginaVerificacao(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write(paginaVerificacaoHTML)
}
