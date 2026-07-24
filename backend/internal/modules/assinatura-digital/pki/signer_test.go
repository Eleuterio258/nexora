package pki

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/digitorus/pdfsign/sign"
)

// testdata/sample.pdf vem de github.com/digitorus/pdfsign/testfiles/testfile20.pdf
// (BSD-2-Clause, Digitorus) — usado só como PDF válido de teste.
func readSamplePDF(t *testing.T) []byte {
	t.Helper()
	data, err := os.ReadFile(filepath.Join("testdata", "sample.pdf"))
	if err != nil {
		t.Fatalf("ler PDF de teste: %v", err)
	}
	return data
}

func hasPAdESMarkers(data []byte) bool {
	temSig := bytes.Contains(data, []byte("/Type/Sig")) || bytes.Contains(data, []byte("/Type /Sig"))
	return temSig && bytes.Contains(data, []byte("/SubFilter")) && bytes.Contains(data, []byte("/ByteRange"))
}

func TestPDFSigner_Sign(t *testing.T) {
	pdfBytes := readSamplePDF(t)

	prov, err := NewDevProvider(filepath.Join(t.TempDir(), "dev.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	signer := NewPDFSigner(NewBasicValidator(), "")

	signed, ev, err := signer.Sign(context.Background(), pdfBytes, sign.SignDataSignatureInfo{
		Name:        "Ana Mussa",
		Location:    "Nexora ERP",
		Reason:      "ASSINATURA DE DESENVOLVIMENTO - NAO valida juridicamente.",
		ContactInfo: "ana@example.co.mz",
	}, prov)
	if err != nil {
		t.Fatalf("Sign: %v", err)
	}

	if len(signed) <= len(pdfBytes) {
		t.Errorf("PDF assinado (%d bytes) não é maior que o original (%d bytes)", len(signed), len(pdfBytes))
	}
	if !hasPAdESMarkers(signed) {
		t.Error("PDF assinado não contém os marcadores PAdES esperados (/Type /Sig, /SubFilter, /ByteRange)")
	}
	if ev.LegalValido {
		t.Error("evidência do provider dev nunca deve ser legalmente válida")
	}
	if ev.Provider != "dev-local" {
		t.Errorf("Provider = %q, want dev-local", ev.Provider)
	}
	if ev.AlgoritmoDigest != "SHA-256" {
		t.Errorf("AlgoritmoDigest = %q, want SHA-256", ev.AlgoritmoDigest)
	}
	if ev.Motivo == "" {
		t.Error("Motivo (Reason) devia ter sido registado na evidência")
	}
}

// TestPDFSigner_IncrementalMultiSignature confirma que um segundo signatário
// consegue assinar por cima de um PDF já assinado (fluxo real com vários
// signatários), em vez de invalidar a primeira assinatura.
func TestPDFSigner_IncrementalMultiSignature(t *testing.T) {
	pdfBytes := readSamplePDF(t)

	prov, err := NewDevProvider(filepath.Join(t.TempDir(), "dev.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	signer := NewPDFSigner(NewBasicValidator(), "")

	firstSigned, _, err := signer.Sign(context.Background(), pdfBytes, sign.SignDataSignatureInfo{Name: "Ana Mussa", Reason: "1ª assinatura"}, prov)
	if err != nil {
		t.Fatalf("primeira assinatura: %v", err)
	}
	if !hasPAdESMarkers(firstSigned) {
		t.Fatal("primeira assinatura não produziu marcadores PAdES")
	}

	secondSigned, _, err := signer.Sign(context.Background(), firstSigned, sign.SignDataSignatureInfo{Name: "Carlos Nhaca", Reason: "2ª assinatura"}, prov)
	if err != nil {
		t.Fatalf("segunda assinatura (incremental sobre PDF já assinado): %v", err)
	}
	if len(secondSigned) <= len(firstSigned) {
		t.Errorf("segunda assinatura não aumentou o tamanho do PDF (%d -> %d)", len(firstSigned), len(secondSigned))
	}
	if !hasPAdESMarkers(secondSigned) {
		t.Error("segunda assinatura não produziu marcadores PAdES")
	}
}

func TestBasicValidator(t *testing.T) {
	prov, err := NewDevProvider(filepath.Join(t.TempDir(), "dev.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	cert, _, _, err := prov.Signer(context.Background())
	if err != nil {
		t.Fatalf("Signer: %v", err)
	}

	ok, motivo, err := NewBasicValidator().Validar(cert)
	if err != nil {
		t.Fatalf("Validar: %v", err)
	}
	if !ok {
		t.Errorf("certificado recém-gerado devia ser válido, motivo: %s", motivo)
	}
}
