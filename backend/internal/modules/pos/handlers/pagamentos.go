package handlers

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
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
func (h *Handler) IniciarPagamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	if h.cfg.NexoraPayAPIKey == "" {
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

	pay := nexorapay.NewClient(h.cfg.NexoraPayBaseURL, h.cfg.NexoraPayAPIKey)

	idempotencyKey := fmt.Sprintf("pos-%d-%d", user.TenantID, time.Now().UnixNano())
	thirdPartyRef := fmt.Sprintf("POS-%d-%d", user.TenantID, time.Now().Unix())
	txRef := fmt.Sprintf("POS%d", time.Now().Unix()%1e8)

	ctx, cancel := context.WithTimeout(r.Context(), 130*time.Second) // ligeiramente > timeout M-Pesa
	defer cancel()

	resp, status, err := pay.Post(ctx, "/v1/payments", idempotencyKey, map[string]any{
		"provider":             body.Provider,
		"serviceAccount":       "pos",
		"transactionReference": txRef,
		"thirdPartyReference":  thirdPartyRef,
		"msisdn":               body.MSISDN,
		"amount":               fmt.Sprintf("%.2f", body.Amount),
	})
	if err != nil {
		jsonErr(w, "Erro ao contactar o gateway de pagamento", http.StatusBadGateway)
		return
	}
	if status != http.StatusCreated && status != http.StatusOK {
		errMsg := "Erro no gateway de pagamento"
		if e, ok := resp["error"].(map[string]any); ok {
			if m, ok := e["message"].(string); ok {
				errMsg = m
			}
		}
		jsonErr(w, errMsg, http.StatusUnprocessableEntity)
		return
	}

	data, _ := resp["data"].(map[string]any)
	gatewayTxnID, _ := data["gatewayTransactionId"].(string)
	responseCode, _ := data["responseCode"].(string)

	jsonOK(w, map[string]any{
		"gateway_txn_id": gatewayTxnID,
		"response_code":  responseCode,
		"provider":       body.Provider,
		"mensagem":       "Pedido de pagamento enviado. Verifique o telemóvel para confirmar.",
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

	if h.cfg.NexoraPayAPIKey == "" {
		jsonErr(w, "Pagamento móvel não configurado", http.StatusServiceUnavailable)
		return
	}

	pay := nexorapay.NewClient(h.cfg.NexoraPayBaseURL, h.cfg.NexoraPayAPIKey)

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
// um token nosso), por isso o tenant nunca vem de mw.GetUser: extrai-se de
// thirdPartyReference, que IniciarPagamento já gera no formato
// "POS-<tenantId>-<unixSeconds>" precisamente para isto.
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
	tenantID, ok := tenantIDDeThirdPartyRef(thirdPartyRef)
	if !ok {
		jsonErr(w, "thirdPartyReference inválida ou em falta", http.StatusBadRequest)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
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

	w.WriteHeader(http.StatusNoContent)
}

// tenantIDDeThirdPartyRef extrai o tenant_id de uma referência no formato
// "POS-<tenantId>-<unixSeconds>" (ver IniciarPagamento).
func tenantIDDeThirdPartyRef(ref string) (int64, bool) {
	partes := strings.Split(ref, "-")
	if len(partes) != 3 || partes[0] != "POS" {
		return 0, false
	}
	id, err := strconv.ParseInt(partes[1], 10, 64)
	if err != nil || id <= 0 {
		return 0, false
	}
	return id, true
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
