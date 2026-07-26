package handlers

import (
	"crypto/sha256"
	"encoding/base64"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPKCEChallengeMatches(t *testing.T) {
	verifier := "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk" // exemplo da própria RFC 7636
	sum := sha256.Sum256([]byte(verifier))
	challenge := base64.RawURLEncoding.EncodeToString(sum[:])

	assert.True(t, pkceChallengeMatches(challenge, verifier))
}

func TestPKCEChallengeMatches_VerifierErrado(t *testing.T) {
	sum := sha256.Sum256([]byte("verifier-correcto"))
	challenge := base64.RawURLEncoding.EncodeToString(sum[:])

	assert.False(t, pkceChallengeMatches(challenge, "verifier-errado"))
}

func TestPKCEChallengeMatches_ChallengeVazio(t *testing.T) {
	assert.False(t, pkceChallengeMatches("", "qualquer-verifier"))
}
