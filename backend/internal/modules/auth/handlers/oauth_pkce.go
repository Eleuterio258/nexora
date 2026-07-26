package handlers

import (
	"crypto/sha256"
	"encoding/base64"
)

// pkceChallengeMatches verifica um code_verifier contra o code_challenge
// gravado em /oauth/authorize (RFC 7636, método S256 — "plain" nunca é
// aceite, ver constraint da migration oauth_authorization_codes).
// challenge = BASE64URL-ENCODE(SHA256(verifier)), sem padding.
func pkceChallengeMatches(challenge, verifier string) bool {
	sum := sha256.Sum256([]byte(verifier))
	computed := base64.RawURLEncoding.EncodeToString(sum[:])
	return computed == challenge
}
