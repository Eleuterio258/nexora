package middleware

import (
	"testing"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"nexora/internal/modules/auth/oauthkeys"
)

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
