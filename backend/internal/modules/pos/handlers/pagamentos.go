package handlers

import (
	"context"
	"encoding/json"
	"fmt"
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
func (h *Handler) StatusPagamento(w http.ResponseWriter, r *http.Request) {
	if h.cfg.NexoraPayAPIKey == "" {
		jsonErr(w, "Pagamento móvel não configurado", http.StatusServiceUnavailable)
		return
	}
	gatewayTxnID := chi.URLParam(r, "gatewayTxnId")

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
	txnStatus, _ := data["transactionStatus"].(string)

	jsonOK(w, map[string]any{
		"gateway_txn_id":     gatewayTxnID,
		"status":             txStatus,
		"transaction_status": txnStatus,
		"completed":          txStatus == "succeeded" && txnStatus == "Completed",
		"cancelled":          txnStatus == "Cancelled" || txnStatus == "Expired",
	}, http.StatusOK)
}
