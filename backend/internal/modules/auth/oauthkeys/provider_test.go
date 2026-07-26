package oauthkeys

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewProvider_SemChaveEGeracaoDesactivada_Falha(t *testing.T) {
	_, err := NewProvider(t.TempDir(), false)
	assert.Error(t, err)
}

func TestNewProvider_GeraEPersisteQuandoPermitido(t *testing.T) {
	dir := t.TempDir()

	p1, err := NewProvider(dir, true)
	require.NoError(t, err)
	require.NotEmpty(t, p1.ActiveKID())

	// Uma segunda instância no mesmo directório deve reutilizar a chave
	// gerada, não criar outra — o kid tem de ser idêntico.
	p2, err := NewProvider(dir, false)
	require.NoError(t, err)
	assert.Equal(t, p1.ActiveKID(), p2.ActiveKID())
}

func TestProvider_SignedTokenVerificaComPublicKeyDoJWKS(t *testing.T) {
	dir := t.TempDir()
	p, err := NewProvider(dir, true)
	require.NoError(t, err)

	pub, ok := p.PublicKey(p.ActiveKID())
	require.True(t, ok)
	assert.NotNil(t, pub)

	jwks := p.JWKS()
	require.Len(t, jwks.Keys, 1)
	assert.Equal(t, p.ActiveKID(), jwks.Keys[0].KeyID)
	assert.Equal(t, "RS256", jwks.Keys[0].Algorithm)
}

func TestProvider_RotacaoMantemChaveAntigaVerificavel(t *testing.T) {
	dir := t.TempDir()

	// Primeira chave.
	p1, err := NewProvider(dir, true)
	require.NoError(t, err)
	oldKID := p1.ActiveKID()

	// Gera uma segunda chave manualmente (simula rotação) e recarrega.
	_, newKID, err := GenerateAndSave(dir)
	require.NoError(t, err)
	require.NotEqual(t, oldKID, newKID)

	p2, err := NewProvider(dir, false)
	require.NoError(t, err)

	assert.Equal(t, newKID, p2.ActiveKID(), "a chave mais recente deve ser a activa")

	_, oldStillKnown := p2.PublicKey(oldKID)
	assert.True(t, oldStillKnown, "a chave antiga continua conhecida para verificar tokens já emitidos")

	assert.Len(t, p2.JWKS().Keys, 2)
}
