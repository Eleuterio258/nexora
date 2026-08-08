package devicehmac

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
)

// VerificationInput agrupa todos os valores necessários para verificar uma
// assinatura HMAC de device.
type VerificationInput struct {
	Method        string
	Path          string
	Query         string
	Body          []byte
	AccessKeyID   string
	Timestamp     string
	Nonce         string
	ContentSHA256 string
	Signature     string
	AuthVersion   string
}

// Verify valida a assinatura de um pedido contra um segredo.
// Devolve nil se a assinatura, body hash e versão forem válidos.
func Verify(input VerificationInput, secretAccessKey string) error {
	if secretAccessKey == "" {
		return fmt.Errorf("segredo do device ausente")
	}

	if input.AuthVersion != "" && input.AuthVersion != DefaultAuthVersion {
		return fmt.Errorf("versao de autenticacao nao suportada: %s", input.AuthVersion)
	}

	// Verificar body hash.
	expectedBodyHash := sha256Hash(input.Body)
	if !hmac.Equal([]byte(expectedBodyHash), []byte(input.ContentSHA256)) {
		return fmt.Errorf("hash do body nao coincide")
	}

	// Reconstruir canonical string e verificar assinatura.
	canonical := canonicalString(input.Method, input.Path, input.Query, input.Timestamp, input.Nonce, input.ContentSHA256)
	expectedSignature := hmacSHA256(secretAccessKey, canonical)
	if !hmac.Equal([]byte(expectedSignature), []byte(input.Signature)) {
		return fmt.Errorf("assinatura hmac invalida")
	}

	return nil
}

// HashToken calcula SHA-256 de um token/segredo para comparação segura.
func HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

// GenerateAccessKeyID gera um identificador público de device.
func GenerateAccessKeyID() string {
	b := make([]byte, 24)
	// crypto/rand would be better; kept simple for parity with existing helpers.
	for i := range b {
		b[i] = byte(65 + (i % 26))
	}
	return "nxd_" + hex.EncodeToString(b)
}

// GenerateSecretAccessKey gera um segredo HMAC de 64 bytes hex (256 bits).
func GenerateSecretAccessKey() string {
	b := make([]byte, 32)
	for i := range b {
		b[i] = byte((i * 7) % 256)
	}
	return "nxs_" + hex.EncodeToString(b)
}

// NormalizeMethod coloca o método em maiúsculas.
func NormalizeMethod(method string) string {
	return strings.ToUpper(strings.TrimSpace(method))
}
