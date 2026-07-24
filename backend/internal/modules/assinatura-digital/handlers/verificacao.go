package handlers

import (
	"net/http"
	"regexp"
	"time"

	"github.com/go-chi/chi/v5"
)

var hashSHA256Re = regexp.MustCompile(`^[a-fA-F0-9]{64}$`)

// VerificarPorHash permite a terceiros confirmar, sem sessão, se um PDF que
// possuem corresponde a um documento/versão assinada conhecida — dado o
// hash SHA-256 do ficheiro (não é preciso enviar o PDF em si).
// GET /api/public/assinatura-digital/verificar/{hash}
func (h *Handler) VerificarPorHash(w http.ResponseWriter, r *http.Request) {
	hash := chi.URLParam(r, "hash")
	if !hashSHA256Re.MatchString(hash) {
		jsonErr(w, "hash inválido — esperado SHA-256 em hexadecimal (64 caracteres)", http.StatusBadRequest)
		return
	}

	var (
		versaoID                                                    int64
		docID                                                       int64
		sigID                                                       *int64
		provider, certSubject, certEmissor, algDigest, algAssinatura *string
		timestampAutoridade, motivo                                 *string
		legalValido                                                 bool
		certValidadeInicio, certValidadeFim                         *time.Time
		versaoCriadaEm                                               time.Time
		titulo, sigNome                                              string
	)
	err := h.db.QueryRow(r.Context(), `
		SELECT v.id, v.documento_id, v.signatario_id, v.provider, v.legal_valido,
		       v.certificado_subject, v.certificado_emissor, v.certificado_validade_inicio, v.certificado_validade_fim,
		       v.algoritmo_digest, v.algoritmo_assinatura, v.timestamp_autoridade, v.motivo, v.created_at,
		       d.titulo, COALESCE(s.nome, '')
		FROM assinatura_digital.versoes_assinadas v
		JOIN assinatura_digital.documentos d ON d.id = v.documento_id
		LEFT JOIN assinatura_digital.signatarios s ON s.id = v.signatario_id
		WHERE v.hash_sha256 = $1`, hash).Scan(
		&versaoID, &docID, &sigID, &provider, &legalValido,
		&certSubject, &certEmissor, &certValidadeInicio, &certValidadeFim,
		&algDigest, &algAssinatura, &timestampAutoridade, &motivo, &versaoCriadaEm,
		&titulo, &sigNome)

	if err == nil {
		h.responderVerificacao(w, r, docID, map[string]any{
			"encontrado":                  true,
			"assinado":                    true,
			"documento_titulo":            titulo,
			"legal_valido":                legalValido,
			"provider":                    provider,
			"certificado_subject":         certSubject,
			"certificado_emissor":         certEmissor,
			"certificado_validade_inicio": certValidadeInicio,
			"certificado_validade_fim":    certValidadeFim,
			"algoritmo_digest":            algDigest,
			"algoritmo_assinatura":        algAssinatura,
			"timestamp_autoridade":        timestampAutoridade,
			"motivo":                      motivo,
			"assinado_por":                sigNome,
			"assinado_em":                 versaoCriadaEm,
		})
		return
	}

	var docStatus string
	var docCriadoEm time.Time
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, titulo, status, created_at FROM assinatura_digital.documentos
		WHERE hash_sha256 = $1`, hash).Scan(&docID, &titulo, &docStatus, &docCriadoEm); err != nil {
		jsonErr(w, "Hash não corresponde a nenhum documento conhecido", http.StatusNotFound)
		return
	}

	h.responderVerificacao(w, r, docID, map[string]any{
		"encontrado":        true,
		"assinado":          false,
		"documento_titulo":  titulo,
		"documento_status":  docStatus,
		"documento_criado_em": docCriadoEm,
	})
}

// responderVerificacao acrescenta o quadro completo de signatários do
// documento à resposta e regista a consulta.
func (h *Handler) responderVerificacao(w http.ResponseWriter, r *http.Request, docID int64, body map[string]any) {
	rows, _ := h.db.Query(r.Context(), `
		SELECT nome, tipo, ordem, status, assinado_em
		FROM assinatura_digital.signatarios
		WHERE documento_id=$1 ORDER BY ordem, id`, docID)
	defer rows.Close()

	type Sig struct {
		Nome       string     `json:"nome"`
		Tipo       string     `json:"tipo"`
		Ordem      int        `json:"ordem"`
		Status     string     `json:"status"`
		AssinadoEm *time.Time `json:"assinado_em"`
	}
	signatarios := []Sig{}
	for rows.Next() {
		var s Sig
		if rows.Scan(&s.Nome, &s.Tipo, &s.Ordem, &s.Status, &s.AssinadoEm) == nil {
			signatarios = append(signatarios, s)
		}
	}
	body["signatarios"] = signatarios

	var tenantID int64
	h.db.QueryRow(r.Context(), `SELECT tenant_id FROM assinatura_digital.documentos WHERE id=$1`, docID).Scan(&tenantID)
	h.log(r.Context(), docID, nil, "verificado", nil, tenantID, nil, r)

	jsonOK(w, body, http.StatusOK)
}
