package handlers

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/pkg/nexorapay"
)

// Item 5 do plano-mudancas-backend-paycore-mobile.md: generalizar o gateway
// Nexora-Pay (M-Pesa/eMola/mKesh), hoje só usado no portal de pagamentos
// escolares, para o POS. Decidido não alterar CriarVenda/pos_sales para um
// fluxo assíncrono de pagamento — em vez disso, estes dois endpoints ficam
// independentes: a app inicia o pagamento, espera a confirmação do
// operador no telemóvel (poll de estado), e só depois chama
// POST /api/pos/sales com o pagamento já confirmado, usando o
// gateway_txn_id devolvido aqui como "referencia" em pagamentos[].

// IniciarPagamento inicia um pagamento móvel via Nexora-Pay.
// Body: {"provider":"mpesa","msisdn":"258841234567","amount":123.45}
//
// O pedido fica registado em integration.payment_intents (via
// h.paySvc.Initiate) ANTES de chamar o gateway, com o próprio id do intent
// como Idempotency-Key — Fase 4 de
// docs/analise-transactional-outbox-backends.md: uma falha de rede a meio
// da chamada fica marcada 'unknown' e é resolvida depois pelo job de
// reconciliação (internal/background/jobs.go), em vez de se perder
// silenciosamente como acontecia com a chave antiga derivada de
// time.Now().
func (h *Handler) IniciarPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	if h.cfg.NexoraPayAPIKey == "" || h.cfg.NexoraPayPublicKey == "" || h.paySvc == nil {
		jsonErr(w, "Pagamento móvel não configurado", http.StatusServiceUnavailable)
		return
	}

	var body struct {
		Provider string  `json:"provider"`
		MSISDN   string  `json:"msisdn"`
		Amount   float64 `json:"amount"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.MSISDN == "" || body.Amount <= 0 {
		jsonErr(w, "msisdn e amount são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Provider == "" {
		body.Provider = "mpesa"
	}

	thirdPartyRef := fmt.Sprintf("POS-%d-%d", user.TenantID, time.Now().Unix())
	txRef := fmt.Sprintf("POS%d", time.Now().Unix()%1e8)

	ctx, cancel := context.WithTimeout(r.Context(), 130*time.Second) // ligeiramente > timeout M-Pesa
	defer cancel()

	intent, err := h.paySvc.Initiate(ctx, nexorapay.InitiateInput{
		TenantID: user.TenantID, SourceModule: "pos",
		Provider: body.Provider, ServiceAccount: "pos",
		MSISDN: body.MSISDN, Amount: body.Amount, Moeda: "MZN",
		TransactionRef: txRef, ThirdPartyRef: thirdPartyRef,
		CreatedBy: &user.ID,
	})
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if intent.Status == nexorapay.IntentFailed {
		errMsg := "Erro no gateway de pagamento"
		if intent.Erro != nil {
			errMsg = *intent.Erro
		}
		jsonErr(w, errMsg, http.StatusUnprocessableEntity)
		return
	}

	var gatewayTxnID, responseCode string
	if intent.GatewayTransactionID != nil {
		gatewayTxnID = *intent.GatewayTransactionID
	}
	if intent.ResponseCode != nil {
		responseCode = *intent.ResponseCode
	}
	mensagem := "Pedido de pagamento enviado. Verifique o telemóvel para confirmar."
	if intent.Status == nexorapay.IntentUnknown {
		mensagem = "Não foi possível confirmar o envio ao gateway. Vamos verificar automaticamente — tente consultar o estado dentro de instantes."
	}

	jsonOK(w, map[string]any{
		"gateway_txn_id": gatewayTxnID,
		"response_code":  responseCode,
		"provider":       body.Provider,
		"status":         intent.Status,
		"mensagem":       mensagem,
	}, http.StatusAccepted)
}

// StatusPagamento consulta o estado de um pagamento iniciado por IniciarPagamento.
// Consulta primeiro a confirmação recebida por WebhookPagamento (mais rápida
// e não depende do gateway estar disponível neste preciso instante); só
// pergunta ao Nexora-Pay directamente se ainda não houver confirmação local
// — ex.: a app começou a fazer poll antes do webhook chegar.
func (h *Handler) StatusPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	gatewayTxnID := chi.URLParam(r, "gatewayTxnId")

	var status, txnStatus string
	if err := h.db.QueryRow(r.Context(), `
		SELECT status, COALESCE(transaction_status,'')
		  FROM pos_payment_confirmations
		 WHERE tenant_id=$1 AND gateway_txn_id=$2`,
		user.TenantID, gatewayTxnID,
	).Scan(&status, &txnStatus); err == nil {
		jsonOK(w, map[string]any{
			"gateway_txn_id":     gatewayTxnID,
			"status":             status,
			"transaction_status": txnStatus,
			"completed":          status == "succeeded" && txnStatus == "Completed",
			"cancelled":          txnStatus == "Cancelled" || txnStatus == "Expired",
			"origem":             "webhook",
		}, http.StatusOK)
		return
	}

	if h.cfg.NexoraPayAPIKey == "" || h.cfg.NexoraPayPublicKey == "" {
		jsonErr(w, "Pagamento móvel não configurado", http.StatusServiceUnavailable)
		return
	}

	pay := nexorapay.NewClient(h.cfg.NexoraPayBaseURL, h.cfg.NexoraPayAPIKey, h.cfg.NexoraPayPublicKey)

	ctx, cancel := context.WithTimeout(r.Context(), 15*time.Second)
	defer cancel()

	resp, _, err := pay.Get(ctx, "/v1/transactions/"+gatewayTxnID)
	if err != nil {
		jsonErr(w, "Erro ao consultar gateway", http.StatusBadGateway)
		return
	}

	data, _ := resp["data"].(map[string]any)
	txStatus, _ := data["status"].(string)
	txnStatus2, _ := data["transactionStatus"].(string)

	jsonOK(w, map[string]any{
		"gateway_txn_id":     gatewayTxnID,
		"status":             txStatus,
		"transaction_status": txnStatus2,
		"completed":          txStatus == "succeeded" && txnStatus2 == "Completed",
		"cancelled":          txnStatus2 == "Cancelled" || txnStatus2 == "Expired",
		"origem":             "poll",
	}, http.StatusOK)
}

// WebhookPagamento recebe a confirmação assíncrona do Nexora-Pay (push, em
// vez de a app ter de fazer poll a StatusPagamento até o gateway lá ter
// resultado). Endpoint público (sem RequireAuth — o gateway externo não tem
// um token nosso).
//
// Passa por integration.inbox_events (h.paySvc.ProcessCallback) antes de
// tocar em qualquer tabela de negócio — Fase 4, item 4, de
// docs/analise-transactional-outbox-backends.md: um callback repetido
// deduplica em vez de reprocessar sempre os campos como acontecia com o
// UPSERT antigo. O tenant_id deixou de vir do parsing de
// thirdPartyReference (frágil) — vem do próprio payment_intent, encontrado
// por gateway_transaction_id, que o ERP gerou e confiou ao gateway.
func (h *Handler) WebhookPagamento(w http.ResponseWriter, r *http.Request) {
	rawBody, err := io.ReadAll(io.LimitReader(r.Body, 2<<20))
	if err != nil {
		jsonErr(w, "Erro ao ler corpo", http.StatusBadRequest)
		return
	}

	if h.cfg.GatewayWebhookSecret != "" {
		if !assinaturaWebhookValida(rawBody, r.Header.Get("X-Signature"), h.cfg.GatewayWebhookSecret) {
			jsonErr(w, "Assinatura inválida", http.StatusUnauthorized)
			return
		}
	}

	var payload map[string]any
	if json.Unmarshal(rawBody, &payload) != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	data, ok := payload["data"].(map[string]any)
	if !ok {
		data = payload
	}
	gatewayTxnID, _ := data["gatewayTransactionId"].(string)
	thirdPartyRef, _ := data["thirdPartyReference"].(string)
	status, _ := data["status"].(string)
	txnStatus, _ := data["transactionStatus"].(string)
	provider, _ := data["provider"].(string)

	if gatewayTxnID == "" {
		jsonErr(w, "gatewayTransactionId em falta", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	result, err := h.paySvc.WithTx(tx).ProcessCallback(r.Context(), nexorapay.CallbackInput{
		GatewayTransactionID: gatewayTxnID,
		Status:               status,
		TransactionStatus:    txnStatus,
		RawPayload:           rawBody,
	})
	if errors.Is(err, nexorapay.ErrIntentNotFound) {
		// Nada que o ERP reconheça — não há tenant_id de confiança para
		// gravar, e não vale a pena o gateway repetir a entrega. Responde
		// 204 na mesma (idempotente do ponto de vista do gateway).
		jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if !result.Duplicate {
		tenantID := result.Intent.TenantID
		if _, err := tx.Exec(r.Context(), `
			INSERT INTO pos_payment_confirmations
			  (tenant_id, gateway_txn_id, third_party_reference, provider, status, transaction_status, payload)
			VALUES ($1,$2,$3,$4,$5,$6,$7)
			ON CONFLICT (tenant_id, gateway_txn_id) DO UPDATE
			   SET status=EXCLUDED.status, transaction_status=EXCLUDED.transaction_status,
			       payload=EXCLUDED.payload, confirmed_at=NOW()`,
			tenantID, gatewayTxnID, thirdPartyRef, provider, status, txnStatus, rawBody,
		); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// assinaturaWebhookValida verifica HMAC-SHA256 no formato "sha256=<hex>" —
// mesmo formato usado pelo webhook de pagamentos escolares (ver
// validarAssinaturaWebhook em gestao-escolar/handlers/operacoes.go); réplica
// local porque essa função não é exportada e é curta o suficiente para não
// justificar extracção para um pacote partilhado.
func assinaturaWebhookValida(body []byte, signature, secret string) bool {
	if len(signature) < 7 || signature[:7] != "sha256=" {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(signature[7:]), []byte(expected))
}
