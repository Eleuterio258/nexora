package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestOAuthClient_SupportsGrant(t *testing.T) {
	c := &OAuthClient{GrantTypes: []string{"password", "refresh_token"}}
	assert.True(t, c.SupportsGrant("password"))
	assert.True(t, c.SupportsGrant("refresh_token"))
	assert.False(t, c.SupportsGrant("client_credentials"))
	assert.False(t, c.SupportsGrant(""))
}

func TestOAuthClient_ValidRedirectURI_ExigeMatchExacto(t *testing.T) {
	c := &OAuthClient{RedirectURIs: []string{"http://localhost:4000/callback"}}

	assert.True(t, c.ValidRedirectURI("http://localhost:4000/callback"))
	// Prefixo/subcaminho NUNCA deve validar — é a vulnerabilidade OAuth2
	// mais comum em implementações de authorization_code.
	assert.False(t, c.ValidRedirectURI("http://localhost:4000/callback/evil"))
	assert.False(t, c.ValidRedirectURI("http://localhost:4000/callback?x=1"))
	assert.False(t, c.ValidRedirectURI("http://evil.example/callback"))
	assert.False(t, c.ValidRedirectURI(""))
}
