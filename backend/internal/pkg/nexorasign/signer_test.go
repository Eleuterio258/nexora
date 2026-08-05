package nexorasign

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"testing"
)

func TestSignProducesAllHeaders(t *testing.T) {
	s := New("nexora_ak_test", "nexora_sk_test")
	headers, err := s.Sign("POST", "/api/v1/biometric/enroll", "", map[string]any{
		"user_id": "123",
		"captures": []map[string]string{
			{"image_base64": "abc"},
		},
	})
	if err != nil {
		t.Fatalf("sign falhou: %v", err)
	}

	required := []string{
		AccessKeyHeader,
		TimestampHeader,
		NonceHeader,
		ContentSHA256Header,
		SignatureHeader,
		AuthVersionHeader,
	}
	for _, h := range required {
		if headers[h] == "" {
			t.Errorf("header %s em falta", h)
		}
	}

	if headers[AccessKeyHeader] != "nexora_ak_test" {
		t.Errorf("access key inesperada: %s", headers[AccessKeyHeader])
	}

	if headers[AuthVersionHeader] != defaultAuthVersion {
		t.Errorf("auth version inesperada: %s", headers[AuthVersionHeader])
	}
}

func TestSignBodyHashMatches(t *testing.T) {
	s := New("nexora_ak_test", "nexora_sk_test")
	payload := map[string]any{
		"b": 2,
		"a": 1,
	}
	headers, err := s.Sign("POST", "/api/v1/biometric/enroll", "", payload)
	if err != nil {
		t.Fatalf("sign falhou: %v", err)
	}

	body, err := SerializeBody(payload)
	if err != nil {
		t.Fatalf("serialize falhou: %v", err)
	}
	expectedHash := sha256.Sum256(body)
	expectedHashStr := hex.EncodeToString(expectedHash[:])

	if headers[ContentSHA256Header] != expectedHashStr {
		t.Errorf("body hash não coincide: got %s, want %s", headers[ContentSHA256Header], expectedHashStr)
	}
}

func TestCanonicalStringAndSignature(t *testing.T) {
	secret := "nexora_sk_test"

	body := []byte(`{"a":1,"b":2}`)
	timestamp := "1234567890"
	nonce := "nonce-uuid"
	bodyHash := sha256Hash(body)

	canonical := canonicalString("POST", "/api/v1/biometric/enroll", "", timestamp, nonce, bodyHash)
	expectedCanonical := strings.Join([]string{
		"POST",
		"/api/v1/biometric/enroll",
		"",
		timestamp,
		nonce,
		bodyHash,
	}, "\n")
	if canonical != expectedCanonical {
		t.Errorf("mensagem canónica inesperada:\n%s\nwant:\n%s", canonical, expectedCanonical)
	}

	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(canonical))
	expectedSig := hex.EncodeToString(mac.Sum(nil))

	sig := hmacSHA256(secret, canonical)
	if sig != expectedSig {
		t.Errorf("assinatura inesperada: %s", sig)
	}
}

func TestSerializeBodySortsKeys(t *testing.T) {
	payload := map[string]any{
		"z": 1,
		"a": 2,
		"m": 3,
	}
	body, err := SerializeBody(payload)
	if err != nil {
		t.Fatalf("serialize falhou: %v", err)
	}
	want := `{"a":2,"m":3,"z":1}`
	if string(body) != want {
		t.Errorf("serialize inesperado: %s, want %s", string(body), want)
	}
}

func TestCanonicalQueryString(t *testing.T) {
	cases := []struct {
		in   string
		want string
	}{
		{"", ""},
		{"b=2&a=1", "a=1&b=2"},
		{"a=2&a=1", "a=1&a=2"},
	}
	for _, c := range cases {
		got := canonicalQueryString(c.in)
		if got != c.want {
			t.Errorf("canonicalQueryString(%q) = %q, want %q", c.in, got, c.want)
		}
	}
}
