// Package devicehmac implementa a assinatura HMAC-SHA256 para autenticação
// de dispositivos físicos (terminais, tablets, leitores NFC) no ERP.
//
// O protocolo é semelhante ao Nexora HMAC usado pelo FaceClock, mas usa
// headers X-Device-* para evitar confusão com autenticação serviço-a-serviço.
package devicehmac

const (
	AccessKeyHeader     = "X-Device-Access-Key"
	TimestampHeader     = "X-Device-Timestamp"
	NonceHeader         = "X-Device-Nonce"
	ContentSHA256Header = "X-Device-Content-SHA256"
	SignatureHeader     = "X-Device-Signature"
	AuthVersionHeader   = "X-Device-Auth-Version"

	DefaultAuthVersion = "NEXORA-HMAC-SHA256-V1"
)
