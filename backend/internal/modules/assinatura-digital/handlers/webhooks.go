package handlers

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"nexora/config"
)

// webhookEvidencia carrega a evidência criptográfica que um provider real
// devolve junto com o documento assinado. Sem isto (providers síncronos como
// dev/intic-stub nem usam webhook), o evento só regista aceitação eletrónica
// — ver processarAssinaturaCompletadaTx.
type webhookEvidencia struct {
	Nivel                     string    `json:"nivel"`
	LegalValido               bool      `json:"legal_valido"`
	CertificadoSubject        string    `json:"certificado_subject"`
	CertificadoEmissor        string    `json:"certificado_emissor"`
	CertificadoSerie          string    `json:"certificado_serie"`
	CertificadoFingerprint    string    `json:"certificado_fingerprint"`
	CertificadoValidadeInicio time.Time `json:"certificado_validade_inicio"`
	CertificadoValidadeFim    time.Time `json:"certificado_validade_fim"`
	AlgoritmoDigest           string    `json:"algoritmo_digest"`
	AlgoritmoAssinatura       string    `json:"algoritmo_assinatura"`
	TimestampAutoridade       string    `json:"timestamp_autoridade"`
	Motivo                    string    `json:"motivo"`
	Localizacao               string    `json:"localizacao"`
}

// webhookPayload define o schema esperado de um evento de provider de
// assinatura. Campos específicos do provider ficam em `dados`. TenantID é
// obrigatório e é sempre confrontado com o tenant real do documento/
// signatário referenciados antes de qualquer mutação (ver *Tx abaixo) —
// nunca é usado sozinho como prova de pertença.
type webhookPayload struct {
	EventID                 string            `json:"event_id"`
	EventType               string            `json:"event_type"`
	Timestamp               time.Time         `json:"timestamp"`
	Nonce                   string            `json:"nonce"`
	TenantID                int64             `json:"tenant_id"`
	DocumentoID             *int64            `json:"documento_id,omitempty"`
	VersaoID                *int64            `json:"versao_id,omitempty"`
	SignatarioID            *int64            `json:"signatario_id,omitempty"`
	DocumentoAssinadoBase64 string            `json:"documento_assinado_base64,omitempty"`
	Evidencia               *webhookEvidencia `json:"evidencia,omitempty"`
	CertificadoFingerprint  string            `json:"certificado_fingerprint,omitempty"`
	Dados                   json.RawMessage   `json:"dados"`
}

// eventosPermitidos lista os tipos de eventos que o webhook aceita processar.
var eventosPermitidos = map[string]bool{
	"signature.completed": true,
	"signature.canceled":  true,
	"signature.expired":   true,
	"certificate.revoked": true,
}

const (
	// maxWebhookAge é a tolerância máxima para um evento no passado (proteção
	// contra replay de eventos antigos).
	maxWebhookAge = 5 * time.Minute
	// maxWebhookSkewFuture é a tolerância máxima para um evento no futuro
	// (relógios de provider ligeiramente adiantados; além disso é suspeito).
	maxWebhookSkewFuture = 1 * time.Minute
)

var errWebhookNonceReutilizado = errors.New("nonce já utilizado por outro evento")
var errSemEvidenciaProvider = errors.New("provider não enviou o documento assinado nem evidência")

func providerPermitido(cfg *config.Config, provider string) bool {
	return slices.Contains(cfg.SignatureWebhookProviders, provider)
}

func isUniqueViolation(err error, constraint string) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23505" && (constraint == "" || pgErr.ConstraintName == constraint)
	}
	return false
}

// ReceberWebhook processa callbacks de providers de assinatura.
// Valida o provider (allow-list + segredo HMAC próprio), proteção contra
// replay (timestamp passado/futuro + nonce único), idempotência com
// reprocessamento de eventos falhados, e executa a ação do evento numa única
// transação que só marca o evento como processado se a mutação for bem
// sucedida.
// POST /api/assinatura-digital/webhooks/{provider}
func (h *Handler) ReceberWebhook(w http.ResponseWriter, r *http.Request) {
	provider := strings.ToLower(strings.TrimSpace(chi.URLParam(r, "provider")))

	if !h.cfg.SignatureWebhookEnabled {
		jsonErr(w, "Webhook temporariamente desativado (endurecimento de segurança pendente)", http.StatusServiceUnavailable)
		return
	}
	if !providerPermitido(h.cfg, provider) {
		jsonErr(w, "Provider não permitido", http.StatusForbidden)
		return
	}
	secret := h.cfg.SignatureWebhookSecrets[provider]
	if secret == "" {
		jsonErr(w, "Webhook não configurado para este provider", http.StatusNotImplemented)
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 10<<20)) // 10MB — pode incluir o PDF assinado
	if err != nil {
		jsonErr(w, "Corpo do pedido inválido", http.StatusBadRequest)
		return
	}

	assinaturaRecebida := r.Header.Get("X-Signature")
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	esperada := hex.EncodeToString(mac.Sum(nil))
	if !hmac.Equal([]byte(assinaturaRecebida), []byte(esperada)) {
		jsonErr(w, "Assinatura do webhook inválida", http.StatusUnauthorized)
		return
	}

	var payload webhookPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		jsonErr(w, "Payload JSON inválido", http.StatusBadRequest)
		return
	}

	if payload.EventID == "" || payload.EventType == "" {
		jsonErr(w, "Payload incompleto: event_id e event_type são obrigatórios", http.StatusBadRequest)
		return
	}
	if payload.TenantID <= 0 {
		jsonErr(w, "Payload incompleto: tenant_id é obrigatório", http.StatusBadRequest)
		return
	}
	if !eventosPermitidos[payload.EventType] {
		jsonErr(w, fmt.Sprintf("Tipo de evento não suportado: %s", payload.EventType), http.StatusBadRequest)
		return
	}

	agora := time.Now()
	if agora.Sub(payload.Timestamp) > maxWebhookAge {
		jsonErr(w, "Evento demasiado antigo (possível replay)", http.StatusBadRequest)
		return
	}
	if payload.Timestamp.Sub(agora) > maxWebhookSkewFuture {
		jsonErr(w, "Timestamp do evento no futuro", http.StatusBadRequest)
		return
	}

	eventID, jaProcessado, err := h.reservarWebhookEvent(r.Context(), provider, payload, body)
	if err != nil {
		if errors.Is(err, errWebhookNonceReutilizado) {
			jsonErr(w, "Nonce já utilizado por outro evento", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro ao registar evento", http.StatusInternalServerError)
		return
	}
	if jaProcessado {
		jsonOK(w, map[string]any{"ok": true, "msg": "Evento já processado"}, http.StatusOK)
		return
	}

	// Processa o evento e só marca processado=TRUE se tudo (incluindo a
	// própria marcação) confirmar na mesma transação — um evento que falhe a
	// meio não fica marcado como processado e pode ser reenviado/repetido.
	if err := h.processarWebhookEventoTx(r.Context(), eventID, provider, payload); err != nil {
		if _, dbErr := h.db.Exec(r.Context(),
			`UPDATE assinatura_digital.webhook_events SET erro=$1 WHERE id=$2`, err.Error(), eventID); dbErr != nil {
			log.Printf("[assinatura-digital] erro ao registar falha de webhook: %v", dbErr)
		}
		jsonErr(w, fmt.Sprintf("Erro ao processar evento: %v", err), http.StatusUnprocessableEntity)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "event_id": payload.EventID}, http.StatusOK)
}

// reservarWebhookEvent reivindica o evento para processamento. Um event_id
// novo é inserido e devolvido com processado=false. Um event_id já
// conhecido devolve o seu estado actual em vez de ser tratado sempre como
// duplicado — só assim um evento que tinha falhado anteriormente
// (processado=false) pode ser reprocessado a partir de um reenvio do
// provider.
func (h *Handler) reservarWebhookEvent(ctx context.Context, provider string, payload webhookPayload, body []byte) (eventID int64, processado bool, err error) {
	var nonce *string
	if payload.Nonce != "" {
		nonce = &payload.Nonce
	}

	err = h.db.QueryRow(ctx, `
		INSERT INTO assinatura_digital.webhook_events (provider, event_id, event_type, payload, nonce, tenant_id)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (provider, event_id) DO NOTHING
		RETURNING id`,
		provider, payload.EventID, payload.EventType, body, nonce, payload.TenantID).Scan(&eventID)
	if err == nil {
		return eventID, false, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		if isUniqueViolation(err, "uq_webhook_events_provider_nonce") {
			return 0, false, errWebhookNonceReutilizado
		}
		return 0, false, fmt.Errorf("reservar evento: %w", err)
	}

	// ON CONFLICT DO NOTHING não devolveu linha: o evento já existe.
	if err := h.db.QueryRow(ctx, `
		SELECT id, processado FROM assinatura_digital.webhook_events
		WHERE provider=$1 AND event_id=$2`, provider, payload.EventID).Scan(&eventID, &processado); err != nil {
		return 0, false, fmt.Errorf("obter evento existente: %w", err)
	}
	return eventID, processado, nil
}

func (h *Handler) processarWebhookEventoTx(ctx context.Context, eventID int64, provider string, payload webhookPayload) error {
	tx, err := h.db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("iniciar transação: %w", err)
	}
	defer tx.Rollback(ctx)

	switch payload.EventType {
	case "signature.completed":
		if err := h.processarAssinaturaCompletadaTx(ctx, tx, provider, payload); err != nil {
			return err
		}
	case "signature.canceled", "signature.expired":
		if err := h.processarAssinaturaCanceladaTx(ctx, tx, provider, payload); err != nil {
			return err
		}
	case "certificate.revoked":
		if err := h.processarCertificadoRevogadoTx(ctx, tx, provider, payload); err != nil {
			return err
		}
	default:
		return fmt.Errorf("evento não implementado: %s", payload.EventType)
	}

	if _, err := tx.Exec(ctx, `
		UPDATE assinatura_digital.webhook_events SET processado=TRUE, erro=NULL WHERE id=$1`, eventID); err != nil {
		return fmt.Errorf("marcar evento como processado: %w", err)
	}
	return tx.Commit(ctx)
}

// processarAssinaturaCompletadaTx regista a confirmação de assinatura
// recebida de um provider externo. O signatário/documento e o tenant do
// evento são verificados contra a base de dados (nunca confiando apenas no
// payload) com a linha bloqueada (FOR UPDATE) para serializar com o fluxo
// interno (marcarAssinado). Sem o PDF assinado + evidência do provider, o
// resultado fica em "aceite_eletronicamente"; com eles, gera uma versão
// criptográfica real e o resultado é "assinado" — nunca o contrário.
func (h *Handler) processarAssinaturaCompletadaTx(ctx context.Context, tx dbQuerier, provider string, payload webhookPayload) error {
	if payload.SignatarioID == nil {
		return fmt.Errorf("signatario_id obrigatório para signature.completed")
	}

	var docID, sigTenantID, docTenantID int64
	var sigStatus string
	if err := tx.QueryRow(ctx, `
		SELECT s.documento_id, s.tenant_id, d.tenant_id, s.status
		FROM assinatura_digital.signatarios s
		JOIN assinatura_digital.documentos d ON d.id = s.documento_id
		WHERE s.id=$1
		FOR UPDATE`, *payload.SignatarioID).Scan(&docID, &sigTenantID, &docTenantID, &sigStatus); err != nil {
		return fmt.Errorf("obter signatário: %w", err)
	}
	if sigTenantID != payload.TenantID || docTenantID != payload.TenantID {
		return fmt.Errorf("evento não corresponde ao tenant do signatário/documento")
	}
	if payload.DocumentoID != nil && *payload.DocumentoID != docID {
		return fmt.Errorf("documento_id do evento não corresponde ao signatário")
	}

	if sigStatus == "assinado" || sigStatus == "aceite_eletronicamente" || sigStatus == "recusado" {
		// Reenvio de um evento já efetivamente aplicado: idempotente, não
		// repete a mutação (evita gerar uma segunda versão assinada).
		return nil
	}
	if sigStatus != "pendente" && sigStatus != "convidado" {
		return fmt.Errorf("signatário em estado inesperado: %s", sigStatus)
	}

	novoStatusSig := "aceite_eletronicamente"
	if err := h.gerarVersaoAPartirDoProviderTx(ctx, tx, payload.TenantID, docID, *payload.SignatarioID, provider, payload); err == nil {
		novoStatusSig = "assinado"
	} else if !errors.Is(err, errSemEvidenciaProvider) {
		return err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE assinatura_digital.signatarios
		SET status=$1, assinado_em=NOW()
		WHERE id=$2`, novoStatusSig, *payload.SignatarioID); err != nil {
		return fmt.Errorf("atualizar signatário: %w", err)
	}

	var pendentes, naoCriptografados int
	if err := tx.QueryRow(ctx, `
		SELECT COUNT(*) FILTER (WHERE status NOT IN ('assinado','aceite_eletronicamente','recusado')),
		       COUNT(*) FILTER (WHERE status='aceite_eletronicamente')
		FROM assinatura_digital.signatarios
		WHERE documento_id=$1`, docID).Scan(&pendentes, &naoCriptografados); err != nil {
		return fmt.Errorf("contar signatários pendentes: %w", err)
	}

	novoStatusDoc := "assinado"
	switch {
	case pendentes > 0:
		novoStatusDoc = "parcialmente_assinado"
	case naoCriptografados > 0:
		novoStatusDoc = "aceite_eletronicamente"
	}

	if _, err := tx.Exec(ctx, `
		UPDATE assinatura_digital.documentos
		SET status=$1, updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, novoStatusDoc, docID, payload.TenantID); err != nil {
		return fmt.Errorf("atualizar documento: %w", err)
	}

	return h.logComDB(ctx, tx, docID, payload.SignatarioID, novoStatusSig,
		map[string]any{"via": "webhook", "provider": provider}, payload.TenantID, nil, nil)
}

// gerarVersaoAPartirDoProviderTx persiste, dentro da transação do evento, a
// versão assinada e a evidência enviadas pelo provider. Devolve
// errSemEvidenciaProvider (não é uma falha do processamento) quando o
// provider não enviou o PDF/evidência — o chamador decide o que isso implica
// para o estado do signatário.
func (h *Handler) gerarVersaoAPartirDoProviderTx(
	ctx context.Context, tx dbQuerier, tenantID, docID, sigID int64, provider string, payload webhookPayload,
) error {
	if payload.DocumentoAssinadoBase64 == "" || payload.Evidencia == nil {
		return errSemEvidenciaProvider
	}

	pdfBytes, err := base64.StdEncoding.DecodeString(payload.DocumentoAssinadoBase64)
	if err != nil {
		return fmt.Errorf("documento_assinado_base64 inválido: %w", err)
	}
	if !bytes.HasPrefix(pdfBytes, pdfMagicBytes) {
		return fmt.Errorf("documento assinado devolvido pelo provider não é um PDF válido")
	}

	hash := sha256.Sum256(pdfBytes)
	hashStr := hex.EncodeToString(hash[:])
	key := contentKey(tenantID, hashStr, ".pdf")
	url, err := h.storage.PutImmutable(ctx, key, pdfBytes, "application/pdf")
	if err != nil {
		return fmt.Errorf("gravar PDF assinado do provider: %w", err)
	}

	ev := payload.Evidencia
	nivel := ev.Nivel
	if nivel == "" {
		nivel = "simples"
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO assinatura_digital.versoes_assinadas (
			documento_id, tenant_id, storage_key, ficheiro_url, hash_sha256, signatario_id,
			provider, legal_valido, nivel_assinatura, certificado_subject, certificado_emissor, certificado_serie,
			certificado_fingerprint, certificado_validade_inicio, certificado_validade_fim,
			algoritmo_digest, algoritmo_assinatura, timestamp_autoridade, motivo, localizacao)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)`,
		docID, tenantID, key, url, hashStr, sigID,
		provider, ev.LegalValido, nivel, ev.CertificadoSubject, ev.CertificadoEmissor, ev.CertificadoSerie,
		ev.CertificadoFingerprint, ev.CertificadoValidadeInicio, ev.CertificadoValidadeFim,
		ev.AlgoritmoDigest, ev.AlgoritmoAssinatura, ev.TimestampAutoridade, ev.Motivo, ev.Localizacao,
	); err != nil {
		return fmt.Errorf("gravar versão assinada do provider: %w", err)
	}
	return nil
}

// processarAssinaturaCanceladaTx trata signature.canceled/signature.expired.
// O tenant do documento é sempre verificado contra o payload antes de
// qualquer mutação.
func (h *Handler) processarAssinaturaCanceladaTx(ctx context.Context, tx dbQuerier, provider string, payload webhookPayload) error {
	if payload.DocumentoID == nil {
		return fmt.Errorf("documento_id obrigatório para %s", payload.EventType)
	}

	var docTenantID int64
	var status string
	if err := tx.QueryRow(ctx, `
		SELECT tenant_id, status FROM assinatura_digital.documentos
		WHERE id=$1
		FOR UPDATE`, *payload.DocumentoID).Scan(&docTenantID, &status); err != nil {
		return fmt.Errorf("obter documento: %w", err)
	}
	if docTenantID != payload.TenantID {
		return fmt.Errorf("evento não corresponde ao tenant do documento")
	}
	if status == "cancelado" {
		return nil // reenvio de um evento já aplicado: idempotente
	}
	if status == "assinado" {
		return fmt.Errorf("documento já concluído, não pode ser cancelado")
	}

	if _, err := tx.Exec(ctx, `
		UPDATE assinatura_digital.documentos
		SET status='cancelado', updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2`, *payload.DocumentoID, payload.TenantID); err != nil {
		return fmt.Errorf("cancelar documento: %w", err)
	}
	return h.logComDB(ctx, tx, *payload.DocumentoID, nil, "cancelado_webhook",
		map[string]any{"provider": provider, "evento": payload.EventType}, payload.TenantID, nil, nil)
}

// processarCertificadoRevogadoTx trata certificate.revoked: localiza todas as
// versões assinadas com o certificado indicado (por fingerprint) para o
// tenant do evento e regista uma validação append-only marcando-as como
// inválidas — nunca apaga nem altera a versão original (evidência
// append-only, ver Fase 1). Sem provider real ligado ainda, mas a lógica já
// não é um no-op: falha explicitamente se não houver fingerprint ou se não
// encontrar nenhuma versão correspondente, em vez de aceitar e ignorar
// silenciosamente o evento.
func (h *Handler) processarCertificadoRevogadoTx(ctx context.Context, tx dbQuerier, provider string, payload webhookPayload) error {
	fingerprint := payload.CertificadoFingerprint
	if fingerprint == "" && payload.Evidencia != nil {
		fingerprint = payload.Evidencia.CertificadoFingerprint
	}
	if fingerprint == "" {
		return fmt.Errorf("certificado_fingerprint obrigatório para certificate.revoked")
	}

	rows, err := tx.Query(ctx, `
		SELECT id, documento_id FROM assinatura_digital.versoes_assinadas
		WHERE tenant_id=$1 AND certificado_fingerprint=$2 AND provider=$3`,
		payload.TenantID, fingerprint, provider)
	if err != nil {
		return fmt.Errorf("procurar versões afetadas: %w", err)
	}
	type versaoAfetada struct{ id, docID int64 }
	var afetadas []versaoAfetada
	for rows.Next() {
		var v versaoAfetada
		if err := rows.Scan(&v.id, &v.docID); err != nil {
			rows.Close()
			return fmt.Errorf("ler versão afetada: %w", err)
		}
		afetadas = append(afetadas, v)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return fmt.Errorf("percorrer versões afetadas: %w", err)
	}
	if len(afetadas) == 0 {
		return fmt.Errorf("nenhuma versão assinada encontrada para o certificado revogado")
	}

	for _, v := range afetadas {
		detalhes, _ := json.Marshal(map[string]any{"certificado_fingerprint": fingerprint, "provider": provider})
		if _, err := tx.Exec(ctx, `
			INSERT INTO assinatura_digital.validacoes
				(documento_id, tenant_id, versao_id, assinaturas, certificado_valido, certificado_motivo, resultado, detalhes)
			VALUES ($1,$2,$3,1,FALSE,'Certificado revogado pelo provider após a assinatura','invalido',$4)`,
			v.docID, payload.TenantID, v.id, detalhes); err != nil {
			return fmt.Errorf("registar validação de certificado revogado: %w", err)
		}
		if err := h.logComDB(ctx, tx, v.docID, nil, "certificado_revogado",
			map[string]any{"provider": provider, "certificado_fingerprint": fingerprint, "versao_id": v.id},
			payload.TenantID, nil, nil); err != nil {
			return err
		}
	}
	return nil
}
