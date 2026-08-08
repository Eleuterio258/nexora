package handlers

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/http"
	"strconv"
	"time"
)

// tenantSignatureMaxSkew é a janela de validade de X-Tenant-Timestamp —
// impede reutilização (replay) de uma assinatura capturada.
const tenantSignatureMaxSkew = 5 * time.Minute

var errInvalidTenantSignature = errors.New("assinatura de tenant inválida")

// resolveTenantBySignature identifica o tenant através de um HMAC-SHA256
// assinado com saas.tenants.recrutamento_api_secret, para chamadores que não
// podem confiar no Host/X-Forwarded-Host mediado pelo Traefik — ex.: um site
// institucional fora da infra do Nexora que chama a API pública directamente
// do lado do servidor. Ao contrário de X-Forwarded-Host (ver requestHost),
// este cabeçalho não é forjável sem conhecer o segredo do tenant.
//
// Cabeçalhos esperados:
//
//	X-Tenant-Code:      código do tenant (saas.tenants.codigo)
//	X-Tenant-Timestamp: unix seconds do pedido
//	X-Tenant-Signature:  hex(HMAC-SHA256(segredo, "<codigo>.<timestamp>.<method>.<path>"))
func (h *Handler) resolveTenantBySignature(r *http.Request, codigo string) (int64, error) {
	tsRaw := r.Header.Get("X-Tenant-Timestamp")
	sigRaw := r.Header.Get("X-Tenant-Signature")
	if tsRaw == "" || sigRaw == "" {
		return 0, errInvalidTenantSignature
	}

	ts, err := strconv.ParseInt(tsRaw, 10, 64)
	if err != nil {
		return 0, errInvalidTenantSignature
	}
	if skew := time.Since(time.Unix(ts, 0)); skew > tenantSignatureMaxSkew || skew < -tenantSignatureMaxSkew {
		return 0, errInvalidTenantSignature
	}

	sig, err := hex.DecodeString(sigRaw)
	if err != nil {
		return 0, errInvalidTenantSignature
	}

	var id int64
	var secret *string
	err = h.db.QueryRow(r.Context(),
		`SELECT id, recrutamento_api_secret FROM saas.tenants WHERE codigo=$1 AND status='ativo'`,
		codigo,
	).Scan(&id, &secret)
	if err != nil || secret == nil || *secret == "" {
		return 0, errInvalidTenantSignature
	}

	mensagem := codigo + "." + tsRaw + "." + r.Method + "." + r.URL.Path
	mac := hmac.New(sha256.New, []byte(*secret))
	mac.Write([]byte(mensagem))

	if !hmac.Equal(sig, mac.Sum(nil)) {
		return 0, errInvalidTenantSignature
	}

	return id, nil
}
