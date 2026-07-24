package pki

import (
	"context"
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"fmt"
	"math/big"
	"os"
	"time"
)

// InticProvider é um **stub/esqueleto** para integração futura com uma
// Autoridade de Certificação reconhecida em Moçambique (ex: INTIC) ou com um
// serviço de assinatura qualificada.
//
// Hoje gera um certificado autoassinado localmente (para não quebrar o fluxo
// de assinatura PAdES), mas está estruturado para ser substituído por chamadas
// reais ao provider quando houverem credenciais e documentação da API.
//
// Para activá-lo, configure SIGNATURE_PROVIDER=intic e SIGNATURE_INTIC_KEY_PATH.
type InticProvider struct {
	cert *x509.Certificate
	key  crypto.Signer
}

// NewInticProvider cria o stub INTIC. Em produção, este construtor deveria
// autenticar-se com o serviço remoto (ex: via certificado mTLS, OAuth2, API key)
// e devolver um signer que faz RPC ao HSM/cloud do provider.
func NewInticProvider(keyPath string) (*InticProvider, error) {
	// Tenta carregar certificado/chave persistidos localmente.
	if cert, key, err := loadInticCert(keyPath); err == nil {
		return &InticProvider{cert: cert, key: key}, nil
	}

	// Se não existirem, gera um par localmente com subject que identifica o
	// ambiente. Isto NÃO é juridicamente válido — serve apenas para não quebrar
	// o fluxo enquanto a integração real não está feita.
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, fmt.Errorf("intic stub: gerar chave: %w", err)
	}

	template := &x509.Certificate{
		SerialNumber: big.NewInt(time.Now().UnixNano()),
		Subject: pkix.Name{
			CommonName:   "Nexora ERP - Stub INTIC (NAO VALIDA JURIDICAMENTE)",
			Organization: []string{"Nexora ERP"},
			Country:      []string{"MZ"},
		},
		NotBefore:             time.Now(),
		NotAfter:              time.Now().AddDate(1, 0, 0),
		KeyUsage:              x509.KeyUsageDigitalSignature,
		BasicConstraintsValid: true,
	}
	certDER, err := x509.CreateCertificate(rand.Reader, template, template, key.Public(), key)
	if err != nil {
		return nil, fmt.Errorf("intic stub: criar certificado: %w", err)
	}
	cert, err := x509.ParseCertificate(certDER)
	if err != nil {
		return nil, fmt.Errorf("intic stub: parse certificado: %w", err)
	}

	if err := saveInticCert(keyPath, certDER, key); err != nil {
		return nil, fmt.Errorf("intic stub: gravar certificado: %w", err)
	}

	return &InticProvider{cert: cert, key: key}, nil
}

func loadInticCert(keyPath string) (*x509.Certificate, crypto.Signer, error) {
	data, err := os.ReadFile(keyPath)
	if err != nil {
		return nil, nil, err
	}
	var cert *x509.Certificate
	var key crypto.Signer
	rest := data
	for {
		block, remaining := pem.Decode(rest)
		if block == nil {
			break
		}
		switch block.Type {
		case "CERTIFICATE":
			if cert, err = x509.ParseCertificate(block.Bytes); err != nil {
				return nil, nil, err
			}
		case "EC PRIVATE KEY":
			if k, err := x509.ParseECPrivateKey(block.Bytes); err == nil {
				key = k
			}
		case "RSA PRIVATE KEY":
			if k, err := x509.ParsePKCS1PrivateKey(block.Bytes); err == nil {
				key = k
			}
		}
		rest = remaining
	}
	if cert == nil || key == nil {
		return nil, nil, fmt.Errorf("ficheiro intic incompleto")
	}
	return cert, key, nil
}

func saveInticCert(keyPath string, certDER []byte, key crypto.Signer) error {
	if err := os.MkdirAll(getDir(keyPath), 0o700); err != nil {
		return err
	}
	var keyDER []byte
	var err error
	switch k := key.(type) {
	case *ecdsa.PrivateKey:
		keyDER, err = x509.MarshalECPrivateKey(k)
		if err != nil {
			return err
		}
		keyDER = pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyDER})
	default:
		return fmt.Errorf("tipo de chave não suportado para persistência")
	}
	buf := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: certDER})
	buf = append(buf, keyDER...)
	return os.WriteFile(keyPath, buf, 0o600)
}

func getDir(path string) string {
	for i := len(path) - 1; i >= 0; i-- {
		if path[i] == '/' || path[i] == '\\' {
			return path[:i]
		}
	}
	return "."
}

func (p *InticProvider) Signer(ctx context.Context) (*x509.Certificate, []*x509.Certificate, crypto.Signer, error) {
	return p.cert, []*x509.Certificate{p.cert}, p.key, nil
}

func (p *InticProvider) Nome() string { return "intic-stub" }

// LegalmenteValido devolve false propositadamente, porque este é apenas um
// stub. Quando a integração real existir, deve devolver true.
func (p *InticProvider) LegalmenteValido() bool { return false }

func (p *InticProvider) Nivel() NivelAssinatura { return NivelSimples }
