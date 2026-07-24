// Package pki implementa a arquitectura-alvo da Fase 2 do módulo
// assinatura-digital (ver README secção 9): um SignatureProvider fornece o
// certificado/chave usados para incorporar uma assinatura PAdES no PDF.
//
// O único provider implementado por agora é o "dev" (ver dev_provider.go),
// que gera um certificado auto-assinado local só para testar o fluxo
// ponta-a-ponta. As suas assinaturas NUNCA são juridicamente válidas — um
// provider real (ex. INTIC) implementaria esta mesma interface quando
// existirem credenciais.
package pki

import (
	"context"
	"crypto"
	"crypto/x509"
)

// NivelAssinatura representa o nível jurídico da assinatura produzida.
type NivelAssinatura string

const (
	NivelSimples     NivelAssinatura = "simples"
	NivelAvancada    NivelAssinatura = "avancada"
	NivelQualificada NivelAssinatura = "qualificada"
)

// SignatureProvider obtém o certificado, a cadeia (leaf→root) e o assinador
// usados para uma assinatura PAdES.
type SignatureProvider interface {
	// Signer devolve o certificado leaf, a cadeia completa (leaf → root) e o
	// assinador criptográfico. Em providers remotos (cloud HSM), signer pode
	// ser um wrapper que faz RPC ao serviço seguro.
	Signer(ctx context.Context) (cert *x509.Certificate, chain []*x509.Certificate, signer crypto.Signer, err error)
	// Nome identifica o provider (guardado como evidência).
	Nome() string
	// LegalmenteValido indica se as assinaturas deste provider têm valor
	// jurídico. O provider "dev" devolve sempre false.
	LegalmenteValido() bool
	// Nivel indica o nível jurídico da assinatura produzida.
	Nivel() NivelAssinatura
}
