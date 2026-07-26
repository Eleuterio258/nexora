package handlers

import (
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestRedirectWithError_PreservaStateEAdicionaError(t *testing.T) {
	r := httptest.NewRequest("GET", "/oauth/authorize", nil)
	w := httptest.NewRecorder()

	redirectWithError(w, r, "http://localhost:4000/callback?ja=existe", "xyz123", "invalid_request")

	assert.Equal(t, 302, w.Code)
	loc := w.Header().Get("Location")
	assert.Contains(t, loc, "error=invalid_request")
	assert.Contains(t, loc, "state=xyz123")
	assert.Contains(t, loc, "ja=existe")
}

func TestRedirectWithError_SemStateNaoAdicionaCampo(t *testing.T) {
	r := httptest.NewRequest("GET", "/oauth/authorize", nil)
	w := httptest.NewRecorder()

	redirectWithError(w, r, "http://localhost:4000/callback", "", "access_denied")

	loc := w.Header().Get("Location")
	assert.Contains(t, loc, "error=access_denied")
	assert.NotContains(t, loc, "state=")
}

func TestRedirectWithError_RedirectURIInvalido(t *testing.T) {
	r := httptest.NewRequest("GET", "/oauth/authorize", nil)
	w := httptest.NewRecorder()

	redirectWithError(w, r, "://not a url", "", "invalid_request")

	assert.Equal(t, 400, w.Code)
}
