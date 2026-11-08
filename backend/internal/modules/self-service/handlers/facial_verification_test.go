package handlers

import (
	"errors"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var testPolicy = facialProofPolicy{MinConfidence: 0.85, MinLiveness: 0.68}

func signedFacialProof(t *testing.T, secret, deviceID string, expiresAt time.Time) string {
	t.Helper()
	return signedFacialProofWithScores(t, secret, deviceID, expiresAt, 0.93, 0.88)
}

func signedFacialProofWithScores(t *testing.T, secret, deviceID string, expiresAt time.Time, confidence, liveness float64) string {
	t.Helper()
	claims := facialVerificationClaims{
		TenantID:        "17",
		DeviceID:        deviceID,
		Purpose:         "facial_attendance",
		ConfidenceScore: confidence,
		LivenessScore:   liveness,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    facialVerificationIssuer,
			Audience:  jwt.ClaimStrings{facialVerificationAudience},
			Subject:   "42",
			ID:        "d55f913d-487d-49e4-9ac8-0551ae97886a",
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
	}
	raw, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(secret))
	if err != nil {
		t.Fatal(err)
	}
	return raw
}

func TestParseFacialVerificationValidatesBindings(t *testing.T) {
	const secret = "test-facial-secret-at-least-32-bytes"
	raw := signedFacialProof(t, secret, "device-1", time.Now().Add(time.Minute))

	claims, err := parseFacialVerification(raw, secret, 42, 17, "device-1", testPolicy)
	if err != nil {
		t.Fatalf("comprovativo valido rejeitado: %v", err)
	}
	if claims.ConfidenceScore != 0.93 || claims.LivenessScore != 0.88 {
		t.Fatalf("scores inesperados: %+v", claims)
	}

	if _, err := parseFacialVerification(raw, secret, 42, 17, "outro-device", testPolicy); !errors.Is(err, errFacialProofInvalid) {
		t.Fatalf("esperava rejeicao por device, obteve %v", err)
	}
	if _, err := parseFacialVerification(raw, secret, 99, 17, "device-1", testPolicy); !errors.Is(err, errFacialProofInvalid) {
		t.Fatalf("esperava rejeicao por utilizador, obteve %v", err)
	}
}

func TestParseFacialVerificationRejectsExpiredProof(t *testing.T) {
	const secret = "test-facial-secret-at-least-32-bytes"
	raw := signedFacialProof(t, secret, "device-1", time.Now().Add(-time.Minute))
	if _, err := parseFacialVerification(raw, secret, 42, 17, "device-1", testPolicy); !errors.Is(err, errFacialProofInvalid) {
		t.Fatalf("esperava comprovativo expirado, obteve %v", err)
	}
}

func TestParseFacialVerificationRejectsScoresBelowPolicy(t *testing.T) {
	const secret = "test-facial-secret-at-least-32-bytes"
	exp := time.Now().Add(time.Minute)

	lowLiveness := signedFacialProofWithScores(t, secret, "device-1", exp, 0.93, 0.40)
	if _, err := parseFacialVerification(lowLiveness, secret, 42, 17, "device-1", testPolicy); !errors.Is(err, errFacialProofInvalid) {
		t.Fatalf("esperava rejeicao por liveness baixo, obteve %v", err)
	}
	lowConfidence := signedFacialProofWithScores(t, secret, "device-1", exp, 0.50, 0.88)
	if _, err := parseFacialVerification(lowConfidence, secret, 42, 17, "device-1", testPolicy); !errors.Is(err, errFacialProofInvalid) {
		t.Fatalf("esperava rejeicao por confianca baixa, obteve %v", err)
	}
}
