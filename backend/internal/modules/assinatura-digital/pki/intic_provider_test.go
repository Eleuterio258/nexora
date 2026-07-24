package pki

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestInticProvider_CriaCertificadoLocal(t *testing.T) {
	dir := t.TempDir()
	keyPath := filepath.Join(dir, "intic-test.pem")

	prov, err := NewInticProvider(keyPath)
	if err != nil {
		t.Fatalf("NewInticProvider falhou: %v", err)
	}

	if prov.Nome() != "intic-stub" {
		t.Errorf("Nome = %q, want %q", prov.Nome(), "intic-stub")
	}
	if prov.LegalmenteValido() {
		t.Error("LegalmenteValido deve ser false em stub")
	}
	if prov.Nivel() != NivelSimples {
		t.Errorf("Nivel = %q, want %q", prov.Nivel(), NivelSimples)
	}

	cert, chain, signer, err := prov.Signer(context.Background())
	if err != nil {
		t.Fatalf("Signer falhou: %v", err)
	}
	if cert == nil || signer == nil {
		t.Fatal("cert ou signer nil")
	}
	if len(chain) == 0 {
		t.Error("cadeia vazia")
	}

	if _, err := os.Stat(keyPath); err != nil {
		t.Errorf("certificado não foi persistido: %v", err)
	}
}
