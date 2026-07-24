package pki

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestNewDevProvider_GeneratesAndPersists(t *testing.T) {
	keyPath := filepath.Join(t.TempDir(), "dev.pem")

	p1, err := NewDevProvider(keyPath)
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	if p1.Nome() != "dev-local" {
		t.Errorf("Nome() = %q, want dev-local", p1.Nome())
	}
	if p1.LegalmenteValido() {
		t.Error("LegalmenteValido() deve ser sempre false para o provider dev")
	}
	if _, err := os.Stat(keyPath); err != nil {
		t.Fatalf("certificado não foi persistido em %s: %v", keyPath, err)
	}

	cert1, chain, signer, err := p1.Signer(context.Background())
	if err != nil {
		t.Fatalf("Signer: %v", err)
	}
	if len(chain) != 1 || chain[0] != cert1 {
		t.Error("cadeia devolvida deve conter só o próprio certificado autoassinado")
	}
	if signer == nil {
		t.Error("Signer não devolveu um crypto.Signer")
	}

	// Uma segunda instância apontada para o mesmo ficheiro deve reutilizar o
	// certificado persistido, não gerar um novo a cada arranque.
	p2, err := NewDevProvider(keyPath)
	if err != nil {
		t.Fatalf("NewDevProvider (reload): %v", err)
	}
	cert2, _, _, err := p2.Signer(context.Background())
	if err != nil {
		t.Fatalf("Signer (reload): %v", err)
	}
	if cert1.SerialNumber.Cmp(cert2.SerialNumber) != 0 {
		t.Error("segunda instância gerou um certificado novo em vez de reutilizar o persistido")
	}
}

func TestNewDevProvider_DifferentPathsGetDifferentCerts(t *testing.T) {
	p1, err := NewDevProvider(filepath.Join(t.TempDir(), "a.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	p2, err := NewDevProvider(filepath.Join(t.TempDir(), "b.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	cert1, _, _, _ := p1.Signer(context.Background())
	cert2, _, _, _ := p2.Signer(context.Background())
	if cert1.SerialNumber.Cmp(cert2.SerialNumber) == 0 {
		t.Error("dois caminhos distintos não deviam produzir o mesmo certificado")
	}
}
