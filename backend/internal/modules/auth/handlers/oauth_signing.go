package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// signOAuthAccessToken assina um access token RS256 com a chave activa do
// Authorization Server (h.oauthKeys), incluindo "kid" no header — é o que
// permite ao FaceClock/Android escolherem a chave pública certa em
// /oauth/jwks e verificarem a assinatura localmente, sem round-trip ao ERP.
// Substitui signAccessWithExpiry (HS256) como caminho de emissão a partir de
// /oauth/token (Fase 2) e, mais tarde, authcode.go/pos_login.go.
//
// scope é a string de permissões RBAC finas ("modulo:acao modulo2:acao2 ..."),
// já calculada por quem chama (ver models.LoadUserAccess) — este helper não
// vai à BD, só assina.
func (h *Handler) signOAuthAccessToken(userID, tenantID, membershipID int64, tipo, escopo, scope string, expiry time.Duration) (token string, jti string, err error) {
	if escopo == "" {
		escopo = "erp"
	}
	jti, err = randomJTI()
	if err != nil {
		return "", "", err
	}
	now := time.Now()
	claims := jwt.MapClaims{
		"iss":    h.cfg.OAuthIssuer,
		"aud":    h.cfg.OAuthAudience,
		"sub":    userID,
		"tid":    tenantID,
		"mid":    membershipID,
		"tipo":   tipo,
		"escopo": escopo, // painel (erp/escola/portal_*) — não confundir com "scope" (permissões RBAC)
		"scope":  scope,
		"jti":    jti,
		"exp":    now.Add(expiry).Unix(),
		"iat":    now.Unix(),
	}
	jwtToken := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	jwtToken.Header["kid"] = h.oauthKeys.ActiveKID()
	signed, err := jwtToken.SignedString(h.oauthKeys.SigningKey())
	if err != nil {
		return "", "", err
	}
	return signed, jti, nil
}

// randomOpaqueToken gera um segredo aleatório de alta entropia (64 bytes,
// hex) para refresh tokens e authorization codes OAuth2 — são opacos,
// validados por hash em BD (mw.HashToken), como já é o padrão de
// auth.sessions e hardware.devices, não JWTs.
func randomOpaqueToken() (string, error) {
	b := make([]byte, 64)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
