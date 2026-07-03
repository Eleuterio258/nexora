package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// nexoraPayClient faz chamadas HTTP ao nexora-pay com X-API-Key.
type nexoraPayClient struct {
	baseURL string
	apiKey  string
}

func (c *nexoraPayClient) post(ctx context.Context, path string, idempotencyKey string, body any) (map[string]any, int, error) {
	data, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(data))
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", c.apiKey)
	if idempotencyKey != "" {
		req.Header.Set("Idempotency-Key", idempotencyKey)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	var result map[string]any
	json.Unmarshal(raw, &result)
	return result, resp.StatusCode, nil
}

func (c *nexoraPayClient) get(ctx context.Context, path string) (map[string]any, int, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+path, nil)
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("X-API-Key", c.apiKey)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	var result map[string]any
	json.Unmarshal(raw, &result)
	return result, resp.StatusCode, nil
}

// ── POST /api/portal/aluno/me/cobrancas/{id}/pagar ───────────────────────────
// Inicia pagamento via nexora-pay (M-Pesa, eMola, mKesh).
// Body: { "msisdn": "258841234567", "provider": "mpesa" }

func (h *Handler) PortalIniciarPagamento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	feeID := chi.URLParam(r, "id")

	if h.cfg.NexoraPayAPIKey == "" {
		jsonErr(w, "Pagamento online não configurado. Contacte a secretaria.", http.StatusServiceUnavailable)
		return
	}

	var body struct {
		MSISDN   string `json:"msisdn"`
		Provider string `json:"provider"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.MSISDN == "" {
		jsonErr(w, "MSISDN é obrigatório (ex: 258841234567)", http.StatusBadRequest)
		return
	}
	if body.Provider == "" {
		body.Provider = "mpesa"
	}

	// Obter dados da cobrança (verificar que pertence ao aluno)
	var valor float64
	var moeda, descricao string
	var studentID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT valor_total-COALESCE(desconto,0)-COALESCE(valor_pago,0),
		       moeda, descricao, student_id
		  FROM gestao_escolar.school_fees
		 WHERE id=$1 AND student_id=$2 AND tenant_id=$3
		   AND status IN ('emitida','parcial')`,
		feeID, u.ID, u.TenantID,
	).Scan(&valor, &moeda, &descricao, &studentID)
	if err != nil || valor <= 0 {
		jsonErr(w, "Cobrança não encontrada, já paga ou sem saldo", http.StatusUnprocessableEntity)
		return
	}

	// Chave de idempotência: garante que retry não duplica
	idempotencyKey := fmt.Sprintf("escola-%s-%d-%d", feeID, u.TenantID, time.Now().Unix())
	thirdPartyRef := fmt.Sprintf("ESC-%s-%d", feeID, u.TenantID)
	txRef := fmt.Sprintf("FEE-%s", feeID)[:20] // max 20 chars

	pay := &nexoraPayClient{
		baseURL: h.cfg.NexoraPayBaseURL,
		apiKey:  h.cfg.NexoraPayAPIKey,
	}

	ctx, cancel := context.WithTimeout(r.Context(), 130*time.Second) // ligeiramente > timeout M-Pesa
	defer cancel()

	resp, status, err := pay.post(ctx, "/v1/payments", idempotencyKey, map[string]any{
		"provider":             body.Provider,
		"serviceAccount":       h.cfg.NexoraPayServiceAccount,
		"transactionReference": txRef,
		"thirdPartyReference":  thirdPartyRef,
		"msisdn":               body.MSISDN,
		"amount":               fmt.Sprintf("%.2f", valor),
	})
	if err != nil {
		log.Printf("[nexora-pay] erro ao iniciar pagamento fee=%s: %v", feeID, err)
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

	// Extrair gatewayTransactionId da resposta
	data, _ := resp["data"].(map[string]any)
	gatewayTxnID, _ := data["gatewayTransactionId"].(string)
	responseCode, _ := data["responseCode"].(string)

	// Registar pagamento pendente no ERP
	feeIDInt, _ := strconv.ParseInt(feeID, 10, 64)
	_, _ = h.db.Exec(r.Context(), `
		INSERT INTO gestao_escolar.school_payments
			(tenant_id, school_fee_id, student_id, external_id, metodo, referencia,
			 valor, moeda, status, payload_gateway)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'pendente',$9::jsonb)
		ON CONFLICT(tenant_id, external_id) DO NOTHING`,
		u.TenantID, feeIDInt, studentID, gatewayTxnID,
		body.Provider, thirdPartyRef, valor, moeda, mustJSON(data),
	)

	jsonOK(w, map[string]any{
		"gateway_txn_id": gatewayTxnID,
		"response_code":  responseCode,
		"provider":       body.Provider,
		"valor":          valor,
		"moeda":          moeda,
		"descricao":      descricao,
		"mensagem":       "Pedido de pagamento enviado. Verifique o seu telemóvel para confirmar.",
	}, http.StatusAccepted)
}

// ── GET /api/portal/aluno/me/cobrancas/{id}/pagamento/{gtid} ─────────────────
// Consulta o estado de um pagamento no nexora-pay e confirma no ERP se completo.

func (h *Handler) PortalStatusPagamento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	feeID := chi.URLParam(r, "id")
	gatewayTxnID := chi.URLParam(r, "gtid")

	if h.cfg.NexoraPayAPIKey == "" {
		jsonErr(w, "Gateway não configurado", http.StatusServiceUnavailable)
		return
	}

	pay := &nexoraPayClient{
		baseURL: h.cfg.NexoraPayBaseURL,
		apiKey:  h.cfg.NexoraPayAPIKey,
	}

	ctx, cancel := context.WithTimeout(r.Context(), 15*time.Second)
	defer cancel()

	resp, _, err := pay.get(ctx, "/v1/transactions/"+gatewayTxnID)
	if err != nil {
		jsonErr(w, "Erro ao consultar gateway", http.StatusBadGateway)
		return
	}

	data, _ := resp["data"].(map[string]any)
	txStatus, _ := data["status"].(string)        // "processing" | "succeeded"
	txnStatus, _ := data["transactionStatus"].(string) // "Completed" | "Cancelled" | "Expired" | "N/A"

	// Se completado, confirmar no ERP
	if txStatus == "succeeded" && txnStatus == "Completed" {
		feeIDInt, _ := strconv.ParseInt(feeID, 10, 64)

		// Actualizar pagamento existente para confirmado
		tag, _ := h.db.Exec(r.Context(), `
			UPDATE gestao_escolar.school_payments
			   SET status='confirmado', conciliado=true, pago_em=NOW(),
			       payload_gateway=$1::jsonb
			 WHERE external_id=$2 AND tenant_id=$3 AND status='pendente'`,
			mustJSON(data), gatewayTxnID, u.TenantID,
		)

		// Se confirmado pela primeira vez, actualizar saldo da cobrança
		if tag.RowsAffected() > 0 {
			var valor float64
			_ = h.db.QueryRow(r.Context(), `SELECT valor FROM gestao_escolar.school_payments WHERE external_id=$1 AND tenant_id=$2`, gatewayTxnID, u.TenantID).Scan(&valor)
			if valor > 0 {
				_, _ = h.db.Exec(r.Context(), `
					UPDATE gestao_escolar.school_fees
					   SET valor_pago = valor_pago + $1,
					       status = CASE
					           WHEN valor_total-COALESCE(desconto,0) <= valor_pago+$1 THEN 'paga'
					           ELSE 'parcial'
					       END,
					       updated_at = NOW()
					 WHERE id=$2 AND tenant_id=$3`,
					valor, feeIDInt, u.TenantID)
			}
		}
	}

	jsonOK(w, map[string]any{
		"gateway_txn_id":    gatewayTxnID,
		"status":            txStatus,
		"transaction_status": txnStatus,
		"completed":         txStatus == "succeeded" && txnStatus == "Completed",
		"cancelled":         txnStatus == "Cancelled" || txnStatus == "Expired",
		"data":              data,
	}, http.StatusOK)
}

func mustJSON(v any) string {
	b, _ := json.Marshal(v)
	return string(b)
}
