package pki

import (
	"bytes"
	"context"
	"path/filepath"
	"testing"

	"github.com/digitorus/pdfsign/sign"
)

// TestVerificarPAdES_AssinaturaDevValidaMasNaoConfiavel confirma o critério
// central da Fase 4: uma assinatura criptograficamente íntegra (digest/CMS
// corretos) mas com um certificado autoassinado (provider dev, sem CA real)
// nunca pode ser reportada como plenamente confiável — só o seria se
// TodosEmissoresConfiaveis fosse true, o que exige uma cadeia até uma raiz do
// sistema operativo ou até uma raiz configurada (nenhuma delas se aplica ao
// certificado dev).
func TestVerificarPAdES_AssinaturaDevValidaMasNaoConfiavel(t *testing.T) {
	pdfBytes := readSamplePDF(t)

	prov, err := NewDevProvider(filepath.Join(t.TempDir(), "dev.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	signer := NewPDFSigner(NewBasicValidator(), "")

	signed, _, err := signer.Sign(context.Background(), pdfBytes, sign.SignDataSignatureInfo{
		Name:   "Ana Mussa",
		Reason: "ASSINATURA DE DESENVOLVIMENTO - NAO valida juridicamente.",
	}, prov)
	if err != nil {
		t.Fatalf("Sign: %v", err)
	}

	resumo, err := VerificarPAdES(signed, nil)
	if err != nil {
		t.Fatalf("VerificarPAdES: %v", err)
	}

	if resumo.NumAssinaturas != 1 {
		t.Fatalf("NumAssinaturas = %d, want 1", resumo.NumAssinaturas)
	}
	if !resumo.TodasValidas {
		t.Errorf("TodasValidas = false, want true (a assinatura em si é criptograficamente íntegra)")
	}
	if resumo.AlgumaRevogada {
		t.Errorf("AlgumaRevogada = true, want false (certificado dev não tem infraestrutura de revogação)")
	}
	if resumo.TodosEmissoresConfiaveis {
		t.Errorf("TodosEmissoresConfiaveis = true, want false — um certificado autoassinado NUNCA deve ser reportado como confiável")
	}
	if len(resumo.Assinaturas) != 1 {
		t.Fatalf("len(Assinaturas) = %d, want 1", len(resumo.Assinaturas))
	}
	det := resumo.Assinaturas[0]
	if det.EmissorConfiavel {
		t.Errorf("Assinaturas[0].EmissorConfiavel = true, want false")
	}
	if det.CertificadoFingerprint == "" {
		t.Error("CertificadoFingerprint não deveria estar vazio")
	}
}

// TestVerificarPAdES_ConteudoAlterado confirma que alterar o conteúdo do PDF
// depois de assinado (dentro da área coberta pelo ByteRange) faz a
// verificação criptográfica falhar — nunca deve ser reportado como válido.
func TestVerificarPAdES_ConteudoAlterado(t *testing.T) {
	pdfBytes := readSamplePDF(t)

	prov, err := NewDevProvider(filepath.Join(t.TempDir(), "dev.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	signer := NewPDFSigner(NewBasicValidator(), "")

	signed, _, err := signer.Sign(context.Background(), pdfBytes, sign.SignDataSignatureInfo{
		Name:   "Ana Mussa",
		Reason: "teste de adulteração",
	}, prov)
	if err != nil {
		t.Fatalf("Sign: %v", err)
	}

	adulterado := bytes.Clone(signed)
	// Altera um byte de conteúdo de texto perto do início do documento
	// (fora da estrutura da assinatura em si) para simular uma alteração do
	// PDF depois de assinado.
	alvo := bytes.Index(adulterado, []byte("%PDF-"))
	if alvo < 0 {
		t.Fatal("marcador %PDF- não encontrado no PDF assinado")
	}
	pos := alvo + len(adulterado[alvo:])/2
	adulterado[pos] ^= 0xFF

	resumo, err := VerificarPAdES(adulterado, nil)
	if err != nil {
		// Uma estrutura suficientemente corrompida pode falhar a interpretar
		// -se de todo — também é um resultado aceitável (não "válido").
		return
	}
	if resumo.TodasValidas {
		t.Error("TodasValidas = true após alteração do conteúdo assinado — devia ter falhado a verificação do digest")
	}
}
