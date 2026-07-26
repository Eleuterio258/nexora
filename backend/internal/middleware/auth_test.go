package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"nexora/internal/modules/auth/oauthkeys"
)

func TestRequireEscopo(t *testing.T) {
	tests := []struct {
		name       string
		user       *AuthUser
		escopos    []string
		wantStatus int
	}{
		{
			name:       "erp permitido para escopo erp",
			user:       &AuthUser{ID: 1, TenantID: 1, Tipo: "funcionario", Escopo: "erp"},
			escopos:    []string{"erp"},
			wantStatus: http.StatusOK,
		},
		{
			name:       "escola rejeitado para escopo erp",
			user:       &AuthUser{ID: 2, TenantID: 1, Tipo: "funcionario", Escopo: "escola"},
			escopos:    []string{"erp"},
			wantStatus: http.StatusForbidden,
		},
		{
			name:       "escola permitido para escopo escola",
			user:       &AuthUser{ID: 3, TenantID: 1, Tipo: "funcionario", Escopo: "escola"},
			escopos:    []string{"escola"},
			wantStatus: http.StatusOK,
		},
		{
			name:       "superadmin bypassa restricao escola",
			user:       &AuthUser{ID: 5, TenantID: 1, Tipo: "superadmin", Escopo: "erp"},
			escopos:    []string{"escola"},
			wantStatus: http.StatusOK,
		},
		{
			name:       "sem utilizador no contexto retorna 401",
			user:       nil,
			escopos:    []string{"erp"},
			wantStatus: http.StatusUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			handler := RequireEscopo(tt.escopos...)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
			}))

			req := httptest.NewRequest(http.MethodGet, "/api/test", nil)
			if tt.user != nil {
				ctx := context.WithValue(req.Context(), UserKey, tt.user)
				req = req.WithContext(ctx)
			}
			rr := httptest.NewRecorder()

			handler.ServeHTTP(rr, req)

			if rr.Code != tt.wantStatus {
				t.Errorf("RequireEscopo() status = %d, want %d", rr.Code, tt.wantStatus)
			}
		})
	}
}

func TestEscopoPermitidoParaPath(t *testing.T) {
	tests := []struct {
		path   string
		escopo string
		want   bool
	}{
		{"/api/escolar/turmas", "escola", true},
		{"/api/escolar/turmas", "erp", false},
		{"/api/faturacao/faturas", "erp", true},
		{"/api/faturacao/faturas", "escola", false},
		{"/api/auth/me", "escola", true},
		{"/api/portal/aluno/me", "erp", true},
		{"/api/rh/funcionarios", "escola", false},
		{"/api/escolar/dashboard", "erp", false},
	}

	for _, tt := range tests {
		t.Run(tt.path+"_"+tt.escopo, func(t *testing.T) {
			if got := escopoPermitidoParaPath(tt.path, tt.escopo); got != tt.want {
				t.Errorf("escopoPermitidoParaPath(%q, %q) = %v, want %v", tt.path, tt.escopo, got, tt.want)
			}
		})
	}
}

// TestJwtKeyFunc_* cobrem o período de transição descrito no comentário de
// jwtKeyFunc: tokens HS256 (legado) e RS256 (emitidos por /oauth/token) têm
// de verificar em simultâneo contra o mesmo keyfunc.
func TestJwtKeyFunc_HS256Legado(t *testing.T) {
	secret := "segredo-de-teste"
	keys, err := oauthkeys.NewProvider(t.TempDir(), true)
	require.NoError(t, err)

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{"sub": 1})
	signed, err := token.SignedString([]byte(secret))
	require.NoError(t, err)

	parsed, err := jwt.Parse(signed, jwtKeyFunc(secret, keys))
	require.NoError(t, err)
	assert.True(t, parsed.Valid)
}

func TestJwtKeyFunc_RS256NovoComKidValido(t *testing.T) {
	secret := "segredo-de-teste"
	keys, err := oauthkeys.NewProvider(t.TempDir(), true)
	require.NoError(t, err)

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims{"sub": 1})
	token.Header["kid"] = keys.ActiveKID()
	signed, err := token.SignedString(keys.SigningKey())
	require.NoError(t, err)

	parsed, err := jwt.Parse(signed, jwtKeyFunc(secret, keys))
	require.NoError(t, err)
	assert.True(t, parsed.Valid)
}

func TestJwtKeyFunc_RS256ComKidDesconhecido(t *testing.T) {
	secret := "segredo-de-teste"
	keys, err := oauthkeys.NewProvider(t.TempDir(), true)
	require.NoError(t, err)

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims{"sub": 1})
	token.Header["kid"] = "kid-que-nao-existe"
	signed, err := token.SignedString(keys.SigningKey())
	require.NoError(t, err)

	_, err = jwt.Parse(signed, jwtKeyFunc(secret, keys))
	assert.Error(t, err)
}

func TestJwtKeyFunc_AlgoritmoNaoSuportadoRejeitado(t *testing.T) {
	secret := "segredo-de-teste"
	keys, err := oauthkeys.NewProvider(t.TempDir(), true)
	require.NoError(t, err)

	token := jwt.NewWithClaims(jwt.SigningMethodNone, jwt.MapClaims{"sub": 1})
	signed, err := token.SignedString(jwt.UnsafeAllowNoneSignatureType)
	require.NoError(t, err)

	_, err = jwt.Parse(signed, jwtKeyFunc(secret, keys))
	assert.Error(t, err)
}
