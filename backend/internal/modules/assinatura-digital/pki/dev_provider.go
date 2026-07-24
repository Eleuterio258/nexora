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
	"path/filepath"
	"time"
)

const devCommonName = "Nexora ERP - Assinatura de Desenvolvimento (NAO VALIDA JURIDICAMENTE)"

// DevProvider gera (ou reutiliza, persistido em keyPath) um par de chaves
// ECDSA P-256 e um certificado X.509 auto-assinado. Serve exclusivamente
// para testar o fluxo de assinatura PAdES ponta-a-ponta — não representa a
// identidade real de nenhum signatário nem tem qualquer valor jurídico.
type DevProvider struct {
	cert *x509.Certificate
	key  *ecdsa.PrivateKey
}

// NewDevProvider carrega o certificado/chave de keyPath se existirem, ou
// gera e persiste um novo par na primeira utilização.
func NewDevProvider(keyPath string) (*DevProvider, error) {
	if cert, key, err := loadDevCert(keyPath); err == nil {
		return &DevProvider{cert: cert, key: key}, nil
	}

	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, fmt.Errorf("gerar chave dev: %w", err)
	}

	template := &x509.Certificate{
		SerialNumber: big.NewInt(time.Now().UnixNano()),
		Subject: pkix.Name{
			CommonName:   devCommonName,
			Organization: []string{"Nexora ERP"},
		},
		NotBefore:             time.Now(),
		NotAfter:              time.Now().AddDate(2, 0, 0),
		KeyUsage:              x509.KeyUsageDigitalSignature,
		BasicConstraintsValid: true,
	}
	certDER, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
	if err != nil {
		return nil, fmt.Errorf("gerar certificado dev: %w", err)
	}
	cert, err := x509.ParseCertificate(certDER)
	if err != nil {
		return nil, fmt.Errorf("parsear certificado dev: %w", err)
	}

	if err := saveDevCert(keyPath, certDER, key); err != nil {
		return nil, fmt.Errorf("gravar certificado dev: %w", err)
	}

	return &DevProvider{cert: cert, key: key}, nil
}

func loadDevCert(keyPath string) (*x509.Certificate, *ecdsa.PrivateKey, error) {
	data, err := os.ReadFile(keyPath)
	if err != nil {
		return nil, nil, err
	}

	var cert *x509.Certificate
	var key *ecdsa.PrivateKey
	rest := data
	for {
		var block *pem.Block
		block, rest = pem.Decode(rest)
		if block == nil {
			break
		}
		switch block.Type {
		case "CERTIFICATE":
			if cert, err = x509.ParseCertificate(block.Bytes); err != nil {
				return nil, nil, err
			}
		case "EC PRIVATE KEY":
			if key, err = x509.ParseECPrivateKey(block.Bytes); err != nil {
				return nil, nil, err
			}
		}
	}
	if cert == nil || key == nil {
		return nil, nil, fmt.Errorf("ficheiro de certificado dev incompleto ou inexistente")
	}
	return cert, key, nil
}

func saveDevCert(keyPath string, certDER []byte, key *ecdsa.PrivateKey) error {
	if err := os.MkdirAll(filepath.Dir(keyPath), 0o700); err != nil {
		return err
	}
	keyDER, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		return err
	}
	buf := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: certDER})
	buf = append(buf, pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyDER})...)
	return os.WriteFile(keyPath, buf, 0o600)
}

func (p *DevProvider) Signer(ctx context.Context) (*x509.Certificate, []*x509.Certificate, crypto.Signer, error) {
	return p.cert, []*x509.Certificate{p.cert}, p.key, nil
}

func (p *DevProvider) Nome() string { return "dev-local" }

func (p *DevProvider) LegalmenteValido() bool { return false }

func (p *DevProvider) Nivel() NivelAssinatura { return NivelSimples }
