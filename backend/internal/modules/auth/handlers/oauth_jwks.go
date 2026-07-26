package handlers

import (
	"encoding/json"
	"net/http"
)

// OAuthJWKS implementa GET /oauth/jwks — endpoint público (sem RequireAuth)
// que publica as chaves públicas RS256 activas do Authorization Server. É
// isto que o FaceClock (e qualquer resource server) usa para verificar
// access tokens localmente, sem round-trip ao ERP.
func (h *Handler) OAuthJWKS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "public, max-age=3600")
	json.NewEncoder(w).Encode(h.oauthKeys.JWKS())
}
