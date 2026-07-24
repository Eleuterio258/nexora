package handlers

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
)

// webhookPayload define o schema mínimo esperado de um evento de provider de
// assinatura. Campos específicos do provider ficam em `dados`.
type webhookPayload struct {
	EventID    string          `json:"event_id"`
	EventType  string          `json:"event_type"`
	Timestamp  time.Time       `json:"timestamp"`
	Nonce      string          `json:"nonce"`
	DocumentoID *int64         `json:"documento_id,omitempty"`
	VersaoID   *int64          `json:"versao_id,omitempty"`
	SignatarioID *int64        `json:"signatario_id,omitempty"`
	Dados      json.RawMessage `json:"dados"`
}

// eventosPermitidos lista os tipos de eventos que o webhook aceita processar.
var eventosPermitidos = map[string]bool{
	"signature.completed":  true,
	"signature.canceled":   true,
	"signature.expired":    true,
	"certificate.revoked":  true,
}

// maxWebhookAge define o tempo máximo de tolerância para um evento (proteção
// contra replay de eventos antigos).
const maxWebhookAge = 5 * time.Minute

// ReceberWebhook processa callbacks de providers de assinatura.
// Valida HMAC, proteção contra replay, idempotência e executa a ação
// correspondente ao evento.
// POST /api/assinatura-digital/webhooks/{provider}
func (h *Handler) ReceberWebhook(w http.ResponseWriter, r *http.Request) {
	provider := chi.URLParam(r, "provider")

	if h.cfg.SignatureWebhookSecret == "" {
		jsonErr(w, "Webhook não configurado", http.StatusNotImplemented)
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20)) // 1MB
	if err != nil {
		jsonErr(w, "Corpo do pedido inválido", http.StatusBadRequest)
		return
	}

	assinaturaRecebida := r.Header.Get("X-Signature")
	mac := hmac.New(sha256.New, []byte(h.cfg.SignatureWebhookSecret))
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

	if !eventosPermitidos[payload.EventType] {
		jsonErr(w, fmt.Sprintf("Tipo de evento não suportado: %s", payload.EventType), http.StatusBadRequest)
		return
	}

	if time.Since(payload.Timestamp) > maxWebhookAge {
		jsonErr(w, "Evento demasiado antigo (possível replay)", http.StatusBadRequest)
		return
	}

	// Idempotência: verifica se o evento já foi processado.
	var jaExiste bool
	if err := h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM assinatura_digital.webhook_events WHERE provider=$1 AND event_id=$2)`,
		provider, payload.EventID).Scan(&jaExiste); err != nil {
		jsonErr(w, "Erro ao verificar idempotência", http.StatusInternalServerError)
		return
	}
	if jaExiste {
		jsonOK(w, map[string]any{"ok": true, "msg": "Evento já processado"}, http.StatusOK)
		return
	}

	// Regista o evento antes de processar.
	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO assinatura_digital.webhook_events (provider, event_id, event_type, payload)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (provider, event_id) DO NOTHING`,
		provider, payload.EventID, payload.EventType, body); err != nil {
		jsonErr(w, "Erro ao registar evento", http.StatusInternalServerError)
		return
	}

	// Processa o evento.
	if err := h.processarWebhook(r.Context(), provider, payload); err != nil {
		if _, dbErr := h.db.Exec(r.Context(), `
			UPDATE assinatura_digital.webhook_events SET processado=FALSE, erro=$1
			WHERE provider=$2 AND event_id=$3`, err.Error(), provider, payload.EventID); dbErr != nil {
			log.Printf("[assinatura-digital] erro ao registar falha de webhook: %v", dbErr)
		}
		jsonErr(w, fmt.Sprintf("Erro ao processar evento: %v", err), http.StatusUnprocessableEntity)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.webhook_events SET processado=TRUE
		WHERE provider=$1 AND event_id=$2`, provider, payload.EventID); err != nil {
		log.Printf("[assinatura-digital] erro ao marcar webhook como processado: %v", err)
	}

	jsonOK(w, map[string]any{"ok": true, "event_id": payload.EventID}, http.StatusOK)
}

func (h *Handler) processarWebhook(ctx context.Context, provider string, payload webhookPayload) error {
	switch payload.EventType {
	case "signature.completed":
		return h.processarAssinaturaCompletada(ctx, provider, payload)
	case "signature.canceled", "signature.expired":
		return h.processarAssinaturaCancelada(ctx, provider, payload)
	case "certificate.revoked":
		return h.processarCertificadoRevogado(ctx, provider, payload)
	default:
		return fmt.Errorf("evento não implementado: %s", payload.EventType)
	}
}

func (h *Handler) processarAssinaturaCompletada(ctx context.Context, provider string, payload webhookPayload) error {
	if payload.SignatarioID == nil {
		return fmt.Errorf("signatario_id obrigatório para signature.completed")
	}

	// Atualiza o signatário para assinado.
	res, err := h.db.Exec(ctx, `
		UPDATE assinatura_digital.signatarios
		SET status='assinado', assinado_em=NOW()
		WHERE id=$1`, *payload.SignatarioID)
	if err != nil {
		return fmt.Errorf("atualizar signatário: %w", err)
	}
	if res.RowsAffected() == 0 {
		return fmt.Errorf("signatário não encontrado")
	}

	// Verifica se ainda há signatários pendentes; se não, conclui o documento.
	var docID int64
	if err := h.db.QueryRow(ctx, `
		SELECT documento_id FROM assinatura_digital.signatarios WHERE id=$1`, *payload.SignatarioID).Scan(&docID); err != nil {
		return fmt.Errorf("obter documento do signatário: %w", err)
	}

	var pendentes int
	if err := h.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM assinatura_digital.signatarios
		WHERE documento_id=$1 AND status NOT IN ('assinado','recusado')`, docID).Scan(&pendentes); err != nil {
		return fmt.Errorf("contar signatários pendentes: %w", err)
	}

	novoStatus := "assinado"
	if pendentes > 0 {
		novoStatus = "parcialmente_assinado"
	}

	if _, err := h.db.Exec(ctx, `
		UPDATE assinatura_digital.documentos
		SET status=$1, updated_at=NOW()
		WHERE id=$2`, novoStatus, docID); err != nil {
		return fmt.Errorf("atualizar documento: %w", err)
	}

	h.log(ctx, docID, payload.SignatarioID, "assinado", map[string]any{"via": "webhook", "provider": provider}, 0, nil, nil)
	return nil
}

func (h *Handler) processarAssinaturaCancelada(ctx context.Context, provider string, payload webhookPayload) error {
	if payload.DocumentoID == nil {
		return fmt.Errorf("documento_id obrigatório para %s", payload.EventType)
	}
	if _, err := h.db.Exec(ctx, `
		UPDATE assinatura_digital.documentos
		SET status='cancelado', updated_at=NOW()
		WHERE id=$1`, *payload.DocumentoID); err != nil {
		return fmt.Errorf("cancelar documento: %w", err)
	}
	h.log(ctx, *payload.DocumentoID, nil, "cancelado_webhook", map[string]any{"provider": provider, "evento": payload.EventType}, 0, nil, nil)
	return nil
}

func (h *Handler) processarCertificadoRevogado(ctx context.Context, provider string, payload webhookPayload) error {
	// Sem provider real, apenas regista o evento. A lógica real dependeria do
	// identificador do certificado/versão fornecido pelo provider.
	log.Printf("[assinatura-digital] certificate.revoked recebido mas sem provider real ligado: %s", string(payload.Dados))
	return nil
}
