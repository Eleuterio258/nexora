package pki

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/digitorus/pdfsign/sign"
)

// TestPDFSigner_TSAIndisponivel confirma que, quando SIGNATURE_TSA_URL aponta
// para um endereço indisponível, a assinatura falha de forma limpa e rápida
// (erro devolvido), em vez de bloquear indefinidamente — o que prenderia a
// transação de BD com a linha do documento bloqueada (FOR UPDATE, ver
// assinatura_transacao.go) e impediria qualquer outro signatário de avançar.
// Ver o patch de timeout em third_party/digitorus-pdfsign/NEXORA_PATCH.md.
func TestPDFSigner_TSAIndisponivel(t *testing.T) {
	pdfBytes := readSamplePDF(t)

	prov, err := NewDevProvider(filepath.Join(t.TempDir(), "dev.pem"))
	if err != nil {
		t.Fatalf("NewDevProvider: %v", err)
	}
	// Porta 1 não tem nenhum serviço à escuta — a ligação é recusada de
	// imediato, sem precisar de esperar por um timeout longo.
	signer := NewPDFSigner(NewBasicValidator(), "http://127.0.0.1:1")

	_, _, err = signer.Sign(context.Background(), pdfBytes, sign.SignDataSignatureInfo{
		Name:   "Ana Mussa",
		Reason: "teste de TSA indisponível",
	}, prov)
	if err == nil {
		t.Fatal("esperava erro ao assinar com uma TSA indisponível, mas Sign() teve sucesso")
	}
}
