package pki

import (
	"context"
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"math/big"
	"testing"
	"time"

	"github.com/digitorus/pdfsign/sign"
)

// expiredCertProvider simula um SignatureProvider cujo certificado já expirou
// — por exemplo, um documento assinado há vários anos, com um certificado
// entretanto fora de validade. NewDevProvider não permite configurar
// NotBefore/NotAfter, por isso este provider mínimo gera o seu próprio
// certificado autoassinado apenas para este teste.
type expiredCertProvider struct {
	cert *x509.Certificate
	key  *ecdsa.PrivateKey
}

func newExpiredCertProvider(t *testing.T) *expiredCertProvider {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("gerar chave: %v", err)
	}
	template := &x509.Certificate{
		SerialNumber: big.NewInt(time.Now().UnixNano()),
		Subject: pkix.Name{
			CommonName:   "Nexora ERP - Teste de Certificado Expirado",
			Organization: []string{"Nexora ERP"},
		},
		NotBefore:             time.Now().AddDate(-3, 0, 0),
		NotAfter:              time.Now().AddDate(-1, 0, 0), // expirou há 1 ano
		KeyUsage:              x509.KeyUsageDigitalSignature,
		BasicConstraintsValid: true,
	}
	certDER, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
	if err != nil {
		t.Fatalf("gerar certificado: %v", err)
	}
	cert, err := x509.ParseCertificate(certDER)
	if err != nil {
		t.Fatalf("parsear certificado: %v", err)
	}
	return &expiredCertProvider{cert: cert, key: key}
}

func (p *expiredCertProvider) Signer(ctx context.Context) (*x509.Certificate, []*x509.Certificate, crypto.Signer, error) {
	return p.cert, []*x509.Certificate{p.cert}, p.key, nil
}
func (p *expiredCertProvider) Nome() string           { return "teste-expirado" }
func (p *expiredCertProvider) LegalmenteValido() bool { return false }
func (p *expiredCertProvider) Nivel() NivelAssinatura { return NivelSimples }

// permissiveValidator aceita qualquer certificado — usado só para produzir,
// neste teste, um PDF assinado com um certificado já expirado (o que
// BasicValidator/ChainValidator reais impedem correctamente no momento de
// assinar — ver TestBasicValidator_Expirado). O objectivo aqui é isolar e
// testar a verificação do lado da VALIDAÇÃO (pki.VerificarPAdES), que tem de
// detectar o certificado expirado independentemente do que aconteceu no
// momento da assinatura.
type permissiveValidator struct{}

func (permissiveValidator) Validar(cert *x509.Certificate) (bool, string, error) {
	return true, "", nil
}

// TestVerificarPAdES_CertificadoExpirado confirma que a validação
// criptográfica detecta um certificado expirado (por exemplo, um documento
// assinado há anos cujo certificado já não é válido) e nunca o classifica
// como tendo um emissor confiável.
func TestVerificarPAdES_CertificadoExpirado(t *testing.T) {
	pdfBytes := readSamplePDF(t)

	prov := newExpiredCertProvider(t)
	signer := NewPDFSigner(permissiveValidator{}, "")

	signed, _, err := signer.Sign(context.Background(), pdfBytes, sign.SignDataSignatureInfo{
		Name:   "Ana Mussa",
		Reason: "teste de certificado expirado",
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
	if resumo.TodosEmissoresConfiaveis {
		t.Error("TodosEmissoresConfiaveis = true — um certificado expirado NUNCA deve ser reportado como confiável")
	}
	det := resumo.Assinaturas[0]
	if det.EmissorConfiavel {
		t.Error("Assinaturas[0].EmissorConfiavel = true, want false (certificado expirado)")
	}
	if det.CertificadoValidadeFim.After(time.Now()) {
		t.Errorf("CertificadoValidadeFim = %s, esperava-se uma data no passado", det.CertificadoValidadeFim)
	}
}
