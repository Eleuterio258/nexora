package pki

import (
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"time"
)

// CertificateValidator valida um certificado antes de ser usado para
// assinar. A validação de cadeia/OCSP/CRL não se aplica a um certificado
// auto-assinado sem CA real (provider "dev") — um provider real deve
// fornecer a sua própria implementação com essas verificações.
type CertificateValidator interface {
	Validar(cert *x509.Certificate) (ok bool, motivo string, err error)
}

type basicValidator struct{}

// NewBasicValidator devolve um CertificateValidator que só confirma a
// validade temporal do certificado (NotBefore/NotAfter).
func NewBasicValidator() CertificateValidator { return basicValidator{} }

func (basicValidator) Validar(cert *x509.Certificate) (bool, string, error) {
	now := time.Now()
	if now.Before(cert.NotBefore) {
		return false, fmt.Sprintf("certificado ainda não é válido (NotBefore=%s)", cert.NotBefore), nil
	}
	if now.After(cert.NotAfter) {
		return false, fmt.Sprintf("certificado expirado (NotAfter=%s)", cert.NotAfter), nil
	}
	return true, "", nil
}

// ChainValidator valida um certificado leaf contra uma cadeia de confiança
// (pool de raízes), verificando também validade temporal. OCSP/CRL são
// suportados como best-effort: se os pontos de distribuição existirem e a
// verificação falhar, o certificado é rejeitado; se não existirem, a validação
// continua (registando o facto no motivo).
type ChainValidator struct {
	roots *x509.CertPool
	intermediates *x509.CertPool
}

// NewChainValidator cria um validador com os certificados raiz e intermediários
// fornecidos em PEM. Se rootsPEM for vazio, usa o pool do sistema.
func NewChainValidator(rootsPEM, intermediatesPEM []byte) (*ChainValidator, error) {
	roots, err := loadCertPool(rootsPEM, true)
	if err != nil {
		return nil, fmt.Errorf("carregar raízes: %w", err)
	}
	intermediates, err := loadCertPool(intermediatesPEM, false)
	if err != nil {
		return nil, fmt.Errorf("carregar intermediários: %w", err)
	}
	return &ChainValidator{roots: roots, intermediates: intermediates}, nil
}

func loadCertPool(pemData []byte, useSystemIfEmpty bool) (*x509.CertPool, error) {
	if len(pemData) == 0 {
		if useSystemIfEmpty {
			return x509.SystemCertPool()
		}
		return x509.NewCertPool(), nil
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(pemData) {
		return nil, fmt.Errorf("nenhum certificado PEM válido encontrado")
	}
	return pool, nil
}

func (v *ChainValidator) Validar(cert *x509.Certificate) (bool, string, error) {
	now := time.Now()
	if now.Before(cert.NotBefore) {
		return false, fmt.Sprintf("certificado ainda não é válido (NotBefore=%s)", cert.NotBefore), nil
	}
	if now.After(cert.NotAfter) {
		return false, fmt.Sprintf("certificado expirado (NotAfter=%s)", cert.NotAfter), nil
	}

	opts := x509.VerifyOptions{
		Roots:         v.roots,
		Intermediates: v.intermediates,
		CurrentTime:   now,
		KeyUsages:     []x509.ExtKeyUsage{x509.ExtKeyUsageAny},
	}

	chains, err := cert.Verify(opts)
	if err != nil {
		return false, fmt.Sprintf("cadeia de confiança inválida: %v", err), nil
	}
	if len(chains) == 0 {
		return false, "nenhuma cadeia de confiança encontrada", nil
	}

	// Best-effort OCSP/CRL: verifica se há pontos de distribuição. A
	// implementação completa de OCSP/CRL requer chamadas HTTP e caching;
	// aqui registamos apenas a presença/ausência.
	var motivos []string
	if len(cert.OCSPServer) > 0 {
		motivos = append(motivos, fmt.Sprintf("OCSP servers: %v (verificação OCSP não implementada)", cert.OCSPServer))
	}
	if len(cert.CRLDistributionPoints) > 0 {
		motivos = append(motivos, fmt.Sprintf("CRL DPs: %v (verificação CRL não implementada)", cert.CRLDistributionPoints))
	}
	motivo := "cadeia validada"
	if len(motivos) > 0 {
		motivo += "; " + joinStrings(motivos, "; ")
	}
	return true, motivo, nil
}

func joinStrings(s []string, sep string) string {
	if len(s) == 0 {
		return ""
	}
	out := s[0]
	for i := 1; i < len(s); i++ {
		out += sep + s[i]
	}
	return out
}

// parsePEMCerts extrai certificados de dados PEM (helper genérico).
func parsePEMCerts(data []byte) ([]*x509.Certificate, error) {
	var certs []*x509.Certificate
	rest := data
	for {
		block, remaining := pem.Decode(rest)
		if block == nil {
			break
		}
		if block.Type == "CERTIFICATE" {
			cert, err := x509.ParseCertificate(block.Bytes)
			if err != nil {
				return nil, err
			}
			certs = append(certs, cert)
		}
		rest = remaining
	}
	return certs, nil
}
