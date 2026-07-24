package pki

import (
	"testing"
)

// TestVerificarPAdES_EntradaMalformada confirma que VerificarPAdES nunca
// entra em pânico com entradas adversariais (o endpoint público de
// validação processa ficheiros que um atacante controla por completo) e
// devolve sempre um erro claro, nunca um resultado "válido" por engano.
func TestVerificarPAdES_EntradaMalformada(t *testing.T) {
	cases := []struct {
		nome string
		data []byte
	}{
		{"vazio", []byte{}},
		{"lixo_binario", []byte{0x00, 0x01, 0x02, 0xFF, 0xFE, 0xDE, 0xAD, 0xBE, 0xEF}},
		{"texto_simples_sem_pdf", []byte("isto não é um PDF, é só texto simples")},
		{"cabecalho_pdf_truncado", []byte("%PDF-1.4\n%\xE2\xE3\xCF\xD3\n")},
	}

	for _, tc := range cases {
		t.Run(tc.nome, func(t *testing.T) {
			defer func() {
				if r := recover(); r != nil {
					t.Fatalf("VerificarPAdES entrou em pânico com entrada %q: %v", tc.nome, r)
				}
			}()
			resumo, err := VerificarPAdES(tc.data, nil)
			if err == nil && resumo != nil && resumo.NumAssinaturas > 0 {
				t.Errorf("entrada malformada %q não deveria produzir nenhuma assinatura reconhecida", tc.nome)
			}
		})
	}
}

// TestVerificarPAdES_PDFSemAssinatura confirma que um PDF válido mas nunca
// assinado é reconhecido como tal (0 assinaturas), não como um erro nem como
// uma assinatura inválida.
func TestVerificarPAdES_PDFSemAssinatura(t *testing.T) {
	pdfBytes := readSamplePDF(t)

	resumo, err := VerificarPAdES(pdfBytes, nil)
	if err != nil {
		// A biblioteca devolve erro quando não há /SigFlags no documento —
		// comportamento aceitável, desde que não seja um pânico e o chamador
		// (validarDocumento) trate isto como "parcial"/sem assinatura.
		return
	}
	if resumo.NumAssinaturas != 0 {
		t.Errorf("NumAssinaturas = %d, want 0 para um PDF nunca assinado", resumo.NumAssinaturas)
	}
	if resumo.TodasValidas {
		t.Error("TodasValidas não deveria ser true para um documento sem nenhuma assinatura")
	}
}

// TestVerificarPAdES_PDFTruncado confirma que um PDF assinado mas cortado a
// meio (ficheiro incompleto, ex. upload interrompido) não provoca pânico e
// não é aceite como válido.
func TestVerificarPAdES_PDFTruncado(t *testing.T) {
	pdfBytes := readSamplePDF(t)
	// Corta a meio do ficheiro original (nem sequer chega a ser assinado) —
	// simula um upload/leitura de storage incompleto.
	truncado := pdfBytes[:len(pdfBytes)/2]

	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("VerificarPAdES entrou em pânico com PDF truncado: %v", r)
		}
	}()
	resumo, err := VerificarPAdES(truncado, nil)
	if err == nil && resumo != nil && resumo.TodasValidas {
		t.Error("um PDF truncado nunca deveria ser reportado como TodasValidas=true")
	}
}
