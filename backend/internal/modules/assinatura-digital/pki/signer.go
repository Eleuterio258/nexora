package pki

import (
	"bytes"
	"context"
	"crypto"
	"crypto/sha256"
	"crypto/x509"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/digitorus/pdf"
	"github.com/digitorus/pdfsign/sign"
)

// Evidencia agrega os dados de uma assinatura PAdES para persistir em
// assinatura_digital.versoes_assinadas.
type Evidencia struct {
	Provider                  string
	LegalValido               bool
	Nivel                     NivelAssinatura
	CertificadoSubject        string
	CertificadoEmissor        string
	CertificadoSerie          string
	CertificadoFingerprint    string
	CertificadoValidadeInicio time.Time
	CertificadoValidadeFim    time.Time
	AlgoritmoDigest           string
	AlgoritmoAssinatura       string
	TimestampAutoridade       string
	Motivo                    string
	Localizacao               string
}

// PDFSigner incorpora uma assinatura PAdES no PDF usando o certificado/chave
// devolvidos pelo SignatureProvider indicado. Usa CertType: ApprovalSignature,
// que permite múltiplas assinaturas incrementais no mesmo PDF (um signatário
// de cada vez).
type PDFSigner struct {
	validator CertificateValidator
	tsaURL    string
}

func NewPDFSigner(validator CertificateValidator, tsaURL string) *PDFSigner {
	return &PDFSigner{validator: validator, tsaURL: tsaURL}
}

// Sign assina pdfBytes e devolve os bytes do novo PDF (com a assinatura
// incorporada) mais a evidência correspondente.
func (s *PDFSigner) Sign(ctx context.Context, pdfBytes []byte, info sign.SignDataSignatureInfo, prov SignatureProvider) ([]byte, *Evidencia, error) {
	cert, chain, signer, err := prov.Signer(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("obter certificado do provider: %w", err)
	}

	ok, motivo, err := s.validator.Validar(cert)
	if err != nil {
		return nil, nil, fmt.Errorf("validar certificado: %w", err)
	}
	if !ok {
		return nil, nil, fmt.Errorf("certificado inválido: %s", motivo)
	}

	info.Date = time.Now()

	signData := sign.SignData{
		Signature: sign.SignDataSignature{
			CertType:   sign.ApprovalSignature,
			DocMDPPerm: sign.AllowFillingExistingFormFieldsAndSignaturesPerms,
			Info:       info,
		},
		Signer:            signer,
		DigestAlgorithm:   crypto.SHA256,
		Certificate:       cert,
		CertificateChains: [][]*x509.Certificate{chain},
	}
	tsaAutoridade := ""
	if s.tsaURL != "" {
		signData.TSA = sign.TSA{URL: s.tsaURL}
		tsaAutoridade = s.tsaURL
	}

	size := int64(len(pdfBytes))
	pdfReader, err := pdf.NewReader(bytes.NewReader(pdfBytes), size)
	if err != nil {
		return nil, nil, fmt.Errorf("ler estrutura do PDF: %w", err)
	}

	var out bytes.Buffer
	if err := sign.Sign(bytes.NewReader(pdfBytes), &out, pdfReader, size, signData); err != nil {
		return nil, nil, fmt.Errorf("assinar PDF: %w", err)
	}

	fingerprint := sha256.Sum256(cert.Raw)

	ev := &Evidencia{
		Provider:                  prov.Nome(),
		LegalValido:               prov.LegalmenteValido(),
		Nivel:                     prov.Nivel(),
		CertificadoSubject:        cert.Subject.String(),
		CertificadoEmissor:        cert.Issuer.String(),
		CertificadoSerie:          cert.SerialNumber.String(),
		CertificadoFingerprint:    hex.EncodeToString(fingerprint[:]),
		CertificadoValidadeInicio: cert.NotBefore,
		CertificadoValidadeFim:    cert.NotAfter,
		AlgoritmoDigest:           "SHA-256",
		AlgoritmoAssinatura:       cert.PublicKeyAlgorithm.String(),
		TimestampAutoridade:       tsaAutoridade,
		Motivo:                    info.Reason,
		Localizacao:               info.Location,
	}

	return out.Bytes(), ev, nil
}
