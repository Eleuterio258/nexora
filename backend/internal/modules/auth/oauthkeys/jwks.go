package oauthkeys

import (
	"github.com/go-jose/go-jose/v4"
)

// JWKS serializa todas as chaves públicas conhecidas (activa + antigas ainda
// válidas) no formato standard consumido por qualquer resource server —
// GET /oauth/jwks devolve isto directamente. O FaceClock usa isto para
// verificar tokens localmente, sem round-trip ao ERP.
func (p *Provider) JWKS() jose.JSONWebKeySet {
	keys := make([]jose.JSONWebKey, 0, len(p.keys))
	for _, kid := range p.KIDs() {
		pub, _ := p.PublicKey(kid)
		keys = append(keys, jose.JSONWebKey{
			Key:       pub,
			KeyID:     kid,
			Algorithm: "RS256",
			Use:       "sig",
		})
	}
	return jose.JSONWebKeySet{Keys: keys}
}
