package pki

import (
	"crypto/x509"
	"path/filepath"
	"testing"
	"time"
)

func TestBasicValidator_Valido(t *testing.T) {
	v := NewBasicValidator()
	cert := &x509.Certificate{
		NotBefore: time.Now().Add(-time.Hour),
		NotAfter:  time.Now().Add(time.Hour),
	}
	ok, motivo, err := v.Validar(cert)
	if err != nil {
		t.Fatalf("err = %v", err)
	}
	if !ok {
		t.Errorf("esperava válido, motivo=%s", motivo)
	}
}

func TestBasicValidator_Expirado(t *testing.T) {
	v := NewBasicValidator()
	cert := &x509.Certificate{
		NotBefore: time.Now().Add(-2 * time.Hour),
		NotAfter:  time.Now().Add(-time.Hour),
	}
	ok, _, _ := v.Validar(cert)
	if ok {
		t.Error("esperava inválido (expirado)")
	}
}

func TestChainValidator_Autoassinado(t *testing.T) {
	keyPath := filepath.Join(t.TempDir(), "dev.pem")
	prov, err := NewDevProvider(keyPath)
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	cert, _, _, err := prov.Signer(nil)
	if err != nil {
		t.Fatalf("Signer: %v", err)
	}

	v, err := NewChainValidator(nil, nil)
	if err != nil {
		t.Fatalf("NewChainValidator: %v", err)
	}

	ok, motivo, err := v.Validar(cert)
	if err != nil {
		t.Fatalf("err = %v", err)
	}
	if ok {
		t.Errorf("certificado autoassinado não deve passar na cadeia do sistema: %s", motivo)
	}
}
