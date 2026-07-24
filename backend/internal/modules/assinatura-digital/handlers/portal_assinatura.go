package handlers

import (
	_ "embed"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

//go:embed static/assinar.html
var paginaAssinaturaHTML []byte

// PaginaAssinatura serve a página pública do portal de assinatura para um
// signatário externo. O token do convite é injetado no HTML através de um
// placeholder simples, permitindo que a página SPA consuma a API sem sessão ERP.
// GET /assinar/{token}
func (h *Handler) PaginaAssinatura(w http.ResponseWriter, r *http.Request) {
	token := chi.URLParam(r, "token")
	if token == "" {
		http.NotFound(w, r)
		return
	}

	// Substituição simples e segura: o token vem da URL e é inserido no HTML
	// como valor de uma variável JavaScript. Escapamos caracteres que possam
	// quebrar a string JS (aspas, quebras de linha, backslash).
	html := string(paginaAssinaturaHTML)
	html = strings.ReplaceAll(html, "{{TOKEN}}", escapeJSString(token))
	html = strings.ReplaceAll(html, "{{API_BASE}}", "/api")

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(html))
}

// escapeJSString escapa uma string para uso seguro dentro de aspas simples em
// JavaScript, prevenindo XSS no placeholder do token.
func escapeJSString(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, "'", "\\'")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	s = strings.ReplaceAll(s, "\n", `\n`)
	s = strings.ReplaceAll(s, "\r", `\r`)
	s = strings.ReplaceAll(s, "\t", `\t`)
	return s
}
