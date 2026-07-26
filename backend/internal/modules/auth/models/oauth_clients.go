package models

import (
	"context"
	"errors"
	"slices"
)

// OAuthClient é uma aplicação registada no Authorization Server — não um
// utilizador nem um dispositivo (ver hardware.devices para isso, que
// deliberadamente não migrou para este registry). Lista pequena e global
// (dezena de linhas): web-erp, android-app, futuros consumidores.
type OAuthClient struct {
	ID               int64
	ClientID         string
	ClientSecretHash *string // NULL para clientes públicos, ou confidenciais ainda sem segredo emitido
	ClientType       string  // "confidential" | "public"
	Nome             string
	GrantTypes       []string
	RedirectURIs     []string
	AllowedScopes    []string
	IsFirstParty     bool
	Ativo            bool
}

var ErrOAuthClientNotFound = errors.New("cliente oauth não encontrado")

// SupportsGrant indica se o cliente está autorizado a usar este grant_type.
func (c *OAuthClient) SupportsGrant(grant string) bool {
	return slices.Contains(c.GrantTypes, grant)
}

// ValidRedirectURI exige correspondência EXACTA — nunca prefixo/regex, é a
// vulnerabilidade mais comum em implementações de authorization_code.
func (c *OAuthClient) ValidRedirectURI(uri string) bool {
	return slices.Contains(c.RedirectURIs, uri)
}

// LoadOAuthClient procura um cliente activo pelo seu client_id público.
func LoadOAuthClient(ctx context.Context, db DBQuerier, clientID string) (*OAuthClient, error) {
	c := &OAuthClient{}
	err := db.QueryRow(ctx, `
		SELECT id, client_id, client_secret_hash, client_type, nome,
		       grant_types, redirect_uris, allowed_scopes, is_first_party, ativo
		  FROM auth.oauth_clients
		 WHERE client_id = $1 AND ativo = true`, clientID,
	).Scan(&c.ID, &c.ClientID, &c.ClientSecretHash, &c.ClientType, &c.Nome,
		&c.GrantTypes, &c.RedirectURIs, &c.AllowedScopes, &c.IsFirstParty, &c.Ativo)
	if err != nil {
		return nil, ErrOAuthClientNotFound
	}
	return c, nil
}
