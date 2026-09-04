package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/pkg/nexorapay"
)

// ── POST /api/portal/aluno/me/cobrancas/{id}/pagar ───────────────────────────
// Inicia pagamento via nexora-pay (M-Pesa, eMola, mKesh).
// Body: { "msisdn": "258841234567", "provider": "mpesa" }

// O pedido fica registado em integration.payment_intents (via
// h.paySvc.Initiate) ANTES de chamar o gateway, com o próprio id do intent
// como Idempotency-Key — Fase 4 de
// docs/analise-transactional-outbox-backends.md. Uma cobrança só pode ter
// um pagamento activo (pending/processing/unknown) de cada vez: um 2º
// pedido enquanto o 1º ainda está em curso devolve esse mesmo intent em vez
// de chamar o gateway outra vez (constraint uq_payment_intents_active_reference).
func (h *Handler) PortalIniciarPagamento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	feeID := chi.URLParam(r, "id")

	if h.cfg.NexoraPayAPIKey == "" || h.cfg.NexoraPayPublicKey == "" || h.paySvc == nil {
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

	feeIDInt, err := strconv.ParseInt(feeID, 10, 64)
	if err != nil {
		jsonErr(w, "Cobrança inválida", http.StatusBadRequest)
		return
	}

	// Obter dados da cobrança (verificar que pertence ao aluno)
	var valor float64
	var moeda, descricao string
	var studentID int64
	err = h.db.QueryRow(r.Context(), `
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

	thirdPartyRef := fmt.Sprintf("ESC-%s-%d", feeID, u.TenantID)
	txRef := fmt.Sprintf("FEE-%s", feeID)
	if len(txRef) > 20 {
		txRef = txRef[:20]
	}

	ctx, cancel := context.WithTimeout(r.Context(), 130*time.Second) // ligeiramente > timeout M-Pesa
	defer cancel()

	intent, err := h.paySvc.Initiate(ctx, nexorapay.InitiateInput{
		TenantID: u.TenantID, SourceModule: "escolar",
		ReferenceType: "school_fee", ReferenceID: &feeIDInt,
		Provider: body.Provider, ServiceAccount: h.cfg.NexoraPayServiceAccount,
		MSISDN: body.MSISDN, Amount: valor, Moeda: moeda,
		TransactionRef: txRef, ThirdPartyRef: thirdPartyRef,
	})
	if err != nil {
		log.Printf("[nexora-pay] erro ao iniciar pagamento fee=%s: %v", feeID, err)
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
		// Só há como registar o pagamento em school_payments (e o aluno
		// poder fazer poll a PortalStatusPagamento) quando já se conhece o
		// gateway_transaction_id. Se o intent ficou 'unknown' (a chamada
		// inicial nunca confirmou sequer ter chegado ao gateway), esta
		// linha não é criada agora — limitação conhecida e aceite: o job
		// de reconciliação resolve o payment_intent sozinho, mas o aluno só
		// vê o pagamento reflectido em school_payments/school_fees numa
		// tentativa posterior (ou depois de a reconciliação o confirmar e
		// um operador reconciliar manualmente).
		if _, err := h.db.Exec(r.Context(), `
			INSERT INTO gestao_escolar.school_payments
				(tenant_id, school_fee_id, student_id, external_id, metodo, referencia,
				 valor, moeda, status, payload_gateway)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'pendente','{}'::jsonb)
			ON CONFLICT(tenant_id, external_id) DO NOTHING`,
			u.TenantID, feeIDInt, studentID, gatewayTxnID,
			body.Provider, thirdPartyRef, valor, moeda,
		); err != nil {
			log.Printf("[nexora-pay] registar pagamento pendente fee=%s: %v", feeID, err)
		}
	}
	if intent.ResponseCode != nil {
		responseCode = *intent.ResponseCode
	}

	mensagem := "Pedido de pagamento enviado. Verifique o seu telemóvel para confirmar."
	if intent.Status == nexorapay.IntentUnknown {
		mensagem = "Não foi possível confirmar o envio ao gateway. Tente novamente dentro de alguns minutos se não receber o pedido no telemóvel."
	}

	jsonOK(w, map[string]any{
		"gateway_txn_id": gatewayTxnID,
		"response_code":  responseCode,
		"provider":       body.Provider,
		"valor":          valor,
		"moeda":          moeda,
		"descricao":      descricao,
		"status":         intent.Status,
		"mensagem":       mensagem,
	}, http.StatusAccepted)
}

// ── GET /api/portal/aluno/me/cobrancas/{id}/pagamento/{gtid} ─────────────────
// Consulta o estado de um pagamento no nexora-pay e confirma no ERP se completo.

func (h *Handler) PortalStatusPagamento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	feeID := chi.URLParam(r, "id")
	gatewayTxnID := chi.URLParam(r, "gtid")

	if h.cfg.NexoraPayAPIKey == "" || h.cfg.NexoraPayPublicKey == "" {
		jsonErr(w, "Gateway não configurado", http.StatusServiceUnavailable)
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
	txStatus, _ := data["status"].(string)             // "processing" | "succeeded"
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

		// Sincroniza o payment_intent correspondente — a confirmação chegou
		// por poll em vez de webhook, mas integration.payment_intents deve
		// ficar coerente de qualquer forma como chegou (Fase 4 de
		// docs/analise-transactional-outbox-backends.md). Best-effort: o
		// pagamento já está confirmado nas tabelas do módulo acima, isto é
		// só para o job de reconciliação não voltar a tentar.
		if h.paySvc != nil {
			respPayload, _ := json.Marshal(data)
			if err := h.paySvc.MarkConfirmedByGatewayTxnID(r.Context(), gatewayTxnID, respPayload); err != nil {
				log.Printf("[nexora-pay] sincronizar payment_intent confirmado gtid=%s: %v", gatewayTxnID, err)
			}
		}
	}

	jsonOK(w, map[string]any{
		"gateway_txn_id":     gatewayTxnID,
		"status":             txStatus,
		"transaction_status": txnStatus,
		"completed":          txStatus == "succeeded" && txnStatus == "Completed",
		"cancelled":          txnStatus == "Cancelled" || txnStatus == "Expired",
		"data":               data,
	}, http.StatusOK)
}

func mustJSON(v any) string {
	b, _ := json.Marshal(v)
	return string(b)
}
