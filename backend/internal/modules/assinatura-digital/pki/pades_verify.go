package pki

import (
	"bytes"
	"crypto/sha256"
	"crypto/x509"
	"encoding/hex"
	"time"

	"github.com/digitorus/pdfsign/verify"
)

// DetalheAssinaturaPAdES é o resultado da verificação criptográfica completa
// de uma assinatura PAdES individual dentro do PDF.
type DetalheAssinaturaPAdES struct {
	Nome                      string    `json:"nome"`
	Motivo                    string    `json:"motivo"`
	Localizacao               string    `json:"localizacao"`
	AssinaturaValida          bool      `json:"assinatura_valida"`
	CertificadoRevogado       bool      `json:"certificado_revogado"`
	EmissorConfiavel          bool      `json:"emissor_confiavel"`
	CertificadoSubject        string    `json:"certificado_subject"`
	CertificadoEmissor        string    `json:"certificado_emissor"`
	CertificadoSerie          string    `json:"certificado_serie"`
	CertificadoFingerprint    string    `json:"certificado_fingerprint"`
	CertificadoValidadeInicio time.Time `json:"certificado_validade_inicio"`
	CertificadoValidadeFim    time.Time `json:"certificado_validade_fim"`
	TimestampEstado           string    `json:"timestamp_estado"`
	TimestampConfiavel        bool      `json:"timestamp_confiavel"`
	VerificacaoErro           string    `json:"verificacao_erro,omitempty"`
	Avisos                    []string  `json:"avisos,omitempty"`
}

// ResumoPAdES agrega o resultado da verificação criptográfica de todas as
// assinaturas presentes num PDF.
type ResumoPAdES struct {
	NumAssinaturas           int                      `json:"num_assinaturas"`
	TodasValidas             bool                     `json:"todas_validas"`
	AlgumaRevogada           bool                     `json:"alguma_revogada"`
	TodosEmissoresConfiaveis bool                     `json:"todos_emissores_confiaveis"`
	Assinaturas              []DetalheAssinaturaPAdES `json:"assinaturas"`
	ErroBiblioteca           string                   `json:"erro_biblioteca,omitempty"`
}

// VerificarPAdES executa a validação criptográfica completa de um PDF
// assinado, cobrindo em conjunto: interpretação da estrutura do PDF,
// validação do(s) ByteRange, extração do CMS incorporado, recálculo e
// comparação do digest assinado, validação da assinatura criptográfica,
// extração do(s) certificado(s), verificação de cadeia (raízes do sistema
// operativo mais, se chainValidator não for nil, as raízes configuradas em
// SIGNATURE_CA_ROOTS_PEM/SIGNATURE_CA_INTERMEDIATES_PEM — necessárias porque
// uma CA como a da INTIC normalmente não está no repositório do SO),
// verificação de OCSP/CRL, e validação de carimbo temporal RFC 3161.
//
// Usa github.com/digitorus/pdfsign/verify — uma biblioteca terceira dedicada
// e testada — em vez de reimplementar parsing ASN.1/CMS à mão, o que seria
// um risco de segurança desnecessário.
func VerificarPAdES(pdfBytes []byte, chainValidator *ChainValidator) (*ResumoPAdES, error) {
	opts := verify.DefaultVerifyOptions()
	opts.EnableExternalRevocationCheck = true

	resp, err := verify.VerifyWithOptions(bytes.NewReader(pdfBytes), int64(len(pdfBytes)), opts)
	if err != nil {
		return nil, err
	}

	resumo := &ResumoPAdES{
		NumAssinaturas: len(resp.Signers),
		ErroBiblioteca: resp.Error,
	}
	if resumo.NumAssinaturas == 0 {
		return resumo, nil
	}

	resumo.TodasValidas = true
	resumo.TodosEmissoresConfiaveis = true

	for _, s := range resp.Signers {
		det := DetalheAssinaturaPAdES{
			Nome:               s.Name,
			Motivo:             s.Reason,
			Localizacao:        s.Location,
			AssinaturaValida:   s.ValidSignature,
			CertificadoRevogado: s.RevokedCertificate,
			EmissorConfiavel:   s.TrustedIssuer,
			TimestampEstado:    s.TimestampStatus,
			TimestampConfiavel: s.TimestampTrusted,
			Avisos:             s.TimeWarnings,
		}

		if !s.ValidSignature {
			resumo.TodasValidas = false
		}
		if s.RevokedCertificate {
			resumo.AlgumaRevogada = true
		}

		emissorConfiavel := s.TrustedIssuer
		var verificacaoTime time.Time
		if s.VerificationTime != nil {
			verificacaoTime = *s.VerificationTime
		} else {
			verificacaoTime = time.Now()
		}

		if len(s.Certificates) > 0 {
			leaf := s.Certificates[0]
			if leaf.Certificate != nil {
				cert := leaf.Certificate
				fingerprint := sha256.Sum256(cert.Raw)
				det.CertificadoSubject = cert.Subject.String()
				det.CertificadoEmissor = cert.Issuer.String()
				det.CertificadoSerie = cert.SerialNumber.String()
				det.CertificadoFingerprint = hex.EncodeToString(fingerprint[:])
				det.CertificadoValidadeInicio = cert.NotBefore
				det.CertificadoValidadeFim = cert.NotAfter
			}
			det.VerificacaoErro = leaf.VerifyError

			// Complementa (nunca substitui) o veredicto da biblioteca: uma CA
			// própria (ex. INTIC) normalmente não está no repositório de
			// raízes do sistema operativo, por isso verificamos também contra
			// as raízes configuradas para este ERP.
			if !emissorConfiavel && chainValidator != nil {
				for _, c := range s.Certificates {
					if c.Certificate == nil {
						continue
					}
					if chainValidator.VerificarCadeiaEm(c.Certificate, verificacaoTime) {
						emissorConfiavel = true
						break
					}
				}
			}
		}

		det.EmissorConfiavel = emissorConfiavel
		if !emissorConfiavel {
			resumo.TodosEmissoresConfiaveis = false
		}

		resumo.Assinaturas = append(resumo.Assinaturas, det)
	}

	return resumo, nil
}

// VerificarCadeiaEm verifica se cert tem uma cadeia de confiança válida,
// contra as raízes/intermediários configurados neste validador, no instante
// `at`. Complementa (não substitui) a verificação contra as raízes do
// sistema operativo já feita por VerificarPAdES.
func (v *ChainValidator) VerificarCadeiaEm(cert *x509.Certificate, at time.Time) bool {
	opts := x509.VerifyOptions{
		Roots:         v.roots,
		Intermediates: v.intermediates,
		CurrentTime:   at,
		KeyUsages:     []x509.ExtKeyUsage{x509.ExtKeyUsageAny},
	}
	_, err := cert.Verify(opts)
	return err == nil
}
