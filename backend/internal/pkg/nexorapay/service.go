package nexorapay

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// DBTX é a interface mínima de acesso à BD usada por este pacote — tanto
// *pgxpool.Pool como pgx.Tx a implementam (mesmo padrão de
// assiduidade.DBTX / push.DBTX, Fases 0 e 3).
type DBTX interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// Estados de integration.payment_intents — Fase 4, item 3, de
// docs/analise-transactional-outbox-backends.md.
const (
	IntentPending    = "pending"
	IntentProcessing = "processing"
	IntentConfirmed  = "confirmed"
	IntentFailed     = "failed"
	IntentUnknown    = "unknown"
)

const paymentMaxAttempts = 5

// paymentBackoff é o atraso antes da próxima reconciliação, indexado por
// número de tentativas já feitas. Mais curto que o das notificações (Fase
// 2): confirmação de pagamento móvel deve resolver-se em minutos (o
// utilizador confirma no telemóvel), não horas.
var paymentBackoff = []time.Duration{
	30 * time.Second,
	1 * time.Minute,
	2 * time.Minute,
	5 * time.Minute,
	15 * time.Minute,
}

func backoffFor(attempts int) time.Duration {
	idx := min(max(attempts-1, 0), len(paymentBackoff)-1)
	return paymentBackoff[idx]
}

// PaymentIntent é uma tentativa de pagamento rastreada em
// integration.payment_intents.
type PaymentIntent struct {
	ID                   string
	TenantID             int64
	SourceModule         string
	Status               string
	Provider             string
	MSISDN               string
	Amount               float64
	Moeda                string
	GatewayTransactionID *string
	ResponseCode         *string
	IdempotencyKey       string
	RequestPayload       []byte
	Erro                 *string
	Attempts             int
}

// PaymentService gere intenções de pagamento persistidas e a sua entrega ao
// Nexora Pay — Fase 4 de docs/analise-transactional-outbox-backends.md.
type PaymentService struct {
	db     DBTX
	client *Client
}

// NewPaymentService cria um serviço sobre a pool de ligações.
func NewPaymentService(db DBTX, client *Client) *PaymentService {
	return &PaymentService{db: db, client: client}
}

// WithTx devolve um serviço cujas escritas participam na transacção
// recebida — nunca faz Commit/Rollback, essa continua a ser
// responsabilidade do chamador (mesmo padrão de
// assiduidade.NewServiceWithTx, Fase 0). Usado por ProcessCallback, que
// precisa de gravar o inbox_event e o payment_intent atomicamente.
func (s *PaymentService) WithTx(tx pgx.Tx) *PaymentService {
	return &PaymentService{db: tx, client: s.client}
}

// InitiateInput são os dados necessários para iniciar um pagamento.
type InitiateInput struct {
	TenantID       int64
	SourceModule   string // "pos" | "escolar"
	ReferenceType  string // "" (pos) | "school_fee" (escolar)
	ReferenceID    *int64
	Provider       string
	ServiceAccount string
	MSISDN         string
	Amount         float64
	Moeda          string
	TransactionRef string
	ThirdPartyRef  string
	CreatedBy      *int64
}

// Initiate regista uma intenção de pagamento ANTES de chamar o gateway
// (nunca ao contrário — é o que garante que uma falha de rede a meio da
// chamada fica registada como 'unknown' em vez de silenciosa) e usa o
// próprio id do intent como Idempotency-Key, estável mesmo que a
// reconciliação tenha de reenviar o pedido mais tarde.
//
// Quando in.ReferenceID não é nil (fluxo escolar) e já existe um intent
// activo (pending/processing/unknown) para a mesma referência, o gateway
// NÃO é chamado outra vez — devolve-se o intent existente, protegido pela
// constraint única uq_payment_intents_active_reference.
func (s *PaymentService) Initiate(ctx context.Context, in InitiateInput) (*PaymentIntent, error) {
	id := uuid.NewString()
	reqBody := map[string]any{
		"provider":             in.Provider,
		"serviceAccount":       in.ServiceAccount,
		"transactionReference": in.TransactionRef,
		"thirdPartyReference":  in.ThirdPartyRef,
		"msisdn":               in.MSISDN,
		"amount":               fmt.Sprintf("%.2f", in.Amount),
	}
	reqPayload, _ := json.Marshal(reqBody)

	_, err := s.db.Exec(ctx, `
		INSERT INTO integration.payment_intents
		  (id, tenant_id, source_module, reference_type, reference_id, idempotency_key,
		   status, provider, msisdn, amount, moeda, third_party_reference, request_payload, created_by)
		VALUES ($1,$2,$3,$4,$5,$1,'pending',$6,$7,$8,$9,$10,$11,$12)`,
		id, in.TenantID, in.SourceModule, nullIfEmpty(in.ReferenceType), in.ReferenceID,
		in.Provider, in.MSISDN, in.Amount, in.Moeda, nullIfEmpty(in.ThirdPartyRef), reqPayload, in.CreatedBy)
	if err != nil {
		if in.ReferenceID != nil && uniqueViolationConstraint(err) == "uq_payment_intents_active_reference" {
			return s.findActiveIntent(ctx, in.TenantID, in.SourceModule, in.ReferenceType, *in.ReferenceID)
		}
		return nil, err
	}

	intent := &PaymentIntent{
		ID: id, TenantID: in.TenantID, SourceModule: in.SourceModule,
		Provider: in.Provider, MSISDN: in.MSISDN, Amount: in.Amount, Moeda: in.Moeda,
		IdempotencyKey: id, RequestPayload: reqPayload,
	}

	resp, status, callErr := s.client.Post(ctx, "/v1/payments", id, reqBody)
	if callErr != nil {
		erro := callErr.Error()
		intent.Status = IntentUnknown
		intent.Erro = &erro
		if err := s.finalizeIntent(ctx, id, IntentUnknown, nil, nil, erro); err != nil {
			log.Printf("[nexorapay] gravar estado unknown do intent %s: %v", id, err)
		}
		return intent, nil
	}

	respPayload, _ := json.Marshal(resp)
	if status == http.StatusCreated || status == http.StatusOK {
		data, _ := resp["data"].(map[string]any)
		gatewayTxnID, _ := data["gatewayTransactionId"].(string)
		responseCode, _ := data["responseCode"].(string)
		intent.Status = IntentProcessing
		intent.GatewayTransactionID = nonEmptyPtr(gatewayTxnID)
		intent.ResponseCode = nonEmptyPtr(responseCode)
		if err := s.finalizeIntent(ctx, id, IntentProcessing, nonEmptyPtr(gatewayTxnID), respPayload, ""); err != nil {
			log.Printf("[nexorapay] gravar estado processing do intent %s: %v", id, err)
		}
		return intent, nil
	}

	errMsg := extractGatewayError(resp)
	intent.Status = IntentFailed
	intent.Erro = &errMsg
	if err := s.finalizeIntent(ctx, id, IntentFailed, nil, respPayload, errMsg); err != nil {
		log.Printf("[nexorapay] gravar estado failed do intent %s: %v", id, err)
	}
	return intent, nil
}

func (s *PaymentService) findActiveIntent(ctx context.Context, tenantID int64, sourceModule, referenceType string, referenceID int64) (*PaymentIntent, error) {
	var pi PaymentIntent
	err := s.db.QueryRow(ctx, `
		SELECT id, tenant_id, source_module, status, provider, msisdn, amount, moeda,
		       gateway_transaction_id, idempotency_key
		  FROM integration.payment_intents
		 WHERE tenant_id=$1 AND source_module=$2 AND reference_type=$3 AND reference_id=$4
		   AND status IN ('pending','processing','unknown')
		 ORDER BY created_at DESC LIMIT 1`,
		tenantID, sourceModule, referenceType, referenceID,
	).Scan(&pi.ID, &pi.TenantID, &pi.SourceModule, &pi.Status, &pi.Provider, &pi.MSISDN,
		&pi.Amount, &pi.Moeda, &pi.GatewayTransactionID, &pi.IdempotencyKey)
	if err != nil {
		return nil, err
	}
	return &pi, nil
}

func (s *PaymentService) finalizeIntent(ctx context.Context, id, status string, gatewayTxnID *string, responsePayload []byte, erro string) error {
	_, err := s.db.Exec(ctx, `
		UPDATE integration.payment_intents
		   SET status=$1,
		       gateway_transaction_id=COALESCE($2, gateway_transaction_id),
		       response_payload=COALESCE($3, response_payload),
		       erro=$4, updated_at=NOW(),
		       confirmed_at = CASE WHEN $1='confirmed' THEN NOW() ELSE confirmed_at END,
		       locked_at=NULL, locked_by=NULL
		 WHERE id=$5`,
		status, gatewayTxnID, nilIfEmptyBytes(responsePayload), nullIfEmpty(erro), id)
	return err
}

// RecoverExpiredLeases devolve à disponibilidade de reconciliação os
// intents cujo lease expirou (worker morto a meio da reconciliação) — não
// mexe em status, só liberta a reserva.
func (s *PaymentService) RecoverExpiredLeases(ctx context.Context, leaseTimeout time.Duration) (int64, error) {
	tag, err := s.db.Exec(ctx, `
		UPDATE integration.payment_intents
		   SET locked_at=NULL, locked_by=NULL
		 WHERE locked_at IS NOT NULL AND locked_at < NOW() - ($1 * INTERVAL '1 second')`,
		leaseTimeout.Seconds())
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

// ClaimForReconciliation reserva até `limit` intents pendentes/processando/
// unknown e vencidos para workerID, numa única instrução SQL — mesmo padrão
// de claimPendingNotifications (internal/background/jobs.go), sem a janela
// que permitiria duas réplicas reconciliarem o mesmo intent ao mesmo tempo.
// A reserva usa só locked_at/locked_by, nunca o campo status — status
// continua a reflectir só o significado de negócio (pending/processing/
// confirmed/failed/unknown), nunca "está a ser reconciliado agora".
func (s *PaymentService) ClaimForReconciliation(ctx context.Context, workerID string, limit int) ([]PaymentIntent, error) {
	rows, err := s.db.Query(ctx, `
		WITH candidatos AS (
			SELECT id
			  FROM integration.payment_intents
			 WHERE status IN ('pending','processing','unknown')
			   AND available_at <= NOW()
			   AND locked_at IS NULL
			 ORDER BY available_at, created_at, id
			 LIMIT $1
			 FOR UPDATE SKIP LOCKED
		)
		UPDATE integration.payment_intents pi
		   SET locked_at = NOW(), locked_by = $2
		  FROM candidatos c
		 WHERE pi.id = c.id
		RETURNING pi.id, pi.tenant_id, pi.source_module, pi.status, pi.provider, pi.msisdn,
		          pi.amount, pi.moeda, pi.gateway_transaction_id, pi.idempotency_key,
		          COALESCE(pi.request_payload, '{}'::jsonb), pi.attempts`,
		limit, workerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var intents []PaymentIntent
	for rows.Next() {
		var pi PaymentIntent
		if err := rows.Scan(&pi.ID, &pi.TenantID, &pi.SourceModule, &pi.Status, &pi.Provider, &pi.MSISDN,
			&pi.Amount, &pi.Moeda, &pi.GatewayTransactionID, &pi.IdempotencyKey,
			&pi.RequestPayload, &pi.Attempts); err != nil {
			continue
		}
		intents = append(intents, pi)
	}
	return intents, rows.Err()
}

// Reconcile resolve um intent ambíguo: se já se conhece o
// gateway_transaction_id, consulta o estado (GET); caso contrário — a
// própria chamada inicial nunca chegou a confirmar-se — reenvia o mesmo
// POST com a mesma idempotency_key a partir do request_payload persistido
// (secção 12 do documento: "reutilizar a mesma chave em retries"). Ao fim
// de paymentMaxAttempts sem resolver, marca 'failed'.
func (s *PaymentService) Reconcile(ctx context.Context, intent PaymentIntent) error {
	if intent.GatewayTransactionID != nil && *intent.GatewayTransactionID != "" {
		return s.reconcileByStatus(ctx, intent)
	}
	return s.reconcileByRetry(ctx, intent)
}

func (s *PaymentService) reconcileByStatus(ctx context.Context, intent PaymentIntent) error {
	resp, _, err := s.client.Get(ctx, "/v1/transactions/"+*intent.GatewayTransactionID)
	if err != nil {
		return s.markRetryOrFail(ctx, intent, err.Error())
	}
	data, _ := resp["data"].(map[string]any)
	txStatus, _ := data["status"].(string)
	txnStatus, _ := data["transactionStatus"].(string)
	respPayload, _ := json.Marshal(resp)

	switch {
	case txStatus == "succeeded" && txnStatus == "Completed":
		return s.finalizeIntent(ctx, intent.ID, IntentConfirmed, intent.GatewayTransactionID, respPayload, "")
	case txnStatus == "Cancelled" || txnStatus == "Expired":
		return s.finalizeIntent(ctx, intent.ID, IntentFailed, intent.GatewayTransactionID, respPayload, "pagamento cancelado ou expirado no gateway")
	default:
		// Ainda em curso do lado do gateway (ex.: à espera do PIN no
		// telemóvel) — agenda nova verificação depois do backoff.
		return s.markRetryOrFail(ctx, intent, "")
	}
}

func (s *PaymentService) reconcileByRetry(ctx context.Context, intent PaymentIntent) error {
	var body map[string]any
	if len(intent.RequestPayload) > 0 {
		_ = json.Unmarshal(intent.RequestPayload, &body)
	}
	resp, status, err := s.client.Post(ctx, "/v1/payments", intent.IdempotencyKey, body)
	if err != nil {
		return s.markRetryOrFail(ctx, intent, err.Error())
	}
	respPayload, _ := json.Marshal(resp)
	if status == http.StatusCreated || status == http.StatusOK {
		data, _ := resp["data"].(map[string]any)
		gatewayTxnID, _ := data["gatewayTransactionId"].(string)
		return s.finalizeIntent(ctx, intent.ID, IntentProcessing, nonEmptyPtr(gatewayTxnID), respPayload, "")
	}
	errMsg := extractGatewayError(resp)
	return s.finalizeIntent(ctx, intent.ID, IntentFailed, nil, respPayload, errMsg)
}

func (s *PaymentService) markRetryOrFail(ctx context.Context, intent PaymentIntent, erro string) error {
	attempts := intent.Attempts + 1
	if attempts >= paymentMaxAttempts {
		msg := "reconciliação esgotou tentativas"
		if erro != "" {
			msg += ": " + erro
		}
		return s.finalizeIntent(ctx, intent.ID, IntentFailed, nil, nil, msg)
	}
	_, err := s.db.Exec(ctx, `
		UPDATE integration.payment_intents
		   SET attempts=$1, erro=$2, available_at=NOW() + ($3 * INTERVAL '1 second'),
		       status='unknown', updated_at=NOW(), locked_at=NULL, locked_by=NULL
		 WHERE id=$4`,
		attempts, nullIfEmpty(erro), backoffFor(attempts).Seconds(), intent.ID)
	return err
}

// MarkConfirmedByGatewayTxnID sincroniza o payment_intent quando a
// confirmação chega por poll (PortalStatusPagamento) em vez de webhook —
// best-effort: um erro aqui é só para log do chamador, nunca deve impedir
// a confirmação do pagamento em si (que já está gravada nas tabelas do
// módulo de negócio antes desta chamada).
func (s *PaymentService) MarkConfirmedByGatewayTxnID(ctx context.Context, gatewayTxnID string, responsePayload []byte) error {
	_, err := s.db.Exec(ctx, `
		UPDATE integration.payment_intents
		   SET status='confirmed', response_payload=COALESCE($2, response_payload),
		       confirmed_at=NOW(), updated_at=NOW(), locked_at=NULL, locked_by=NULL
		 WHERE gateway_transaction_id=$1 AND status <> 'confirmed'`,
		gatewayTxnID, nilIfEmptyBytes(responsePayload))
	return err
}

// CallbackInput são os dados extraídos de um webhook do Nexora Pay.
type CallbackInput struct {
	EventID              string // se o gateway enviar um id de evento próprio
	GatewayTransactionID string
	Status               string // "succeeded" | "processing" | ...
	TransactionStatus    string // "Completed" | "Cancelled" | "Expired" | ...
	RawPayload           []byte
}

// CallbackResult é o resultado de ProcessCallback.
type CallbackResult struct {
	Duplicate bool
	Intent    *PaymentIntent
}

// ErrIntentNotFound é devolvido por ProcessCallback quando o
// gatewayTransactionId do callback não corresponde a nenhum payment_intent
// conhecido.
var ErrIntentNotFound = errors.New("nexorapay: payment_intent não encontrado para o gateway_transaction_id")

// ProcessCallback grava o callback em integration.inbox_events (Fase 1) e
// actualiza o payment_intent correspondente — mesmo padrão de
// processReenrollWebhook
// (internal/modules/recursos-humanos/handlers/biometria_reenroll.go):
// INSERT ... ON CONFLICT DO NOTHING RETURNING id, pgx.ErrNoRows classifica
// o evento como duplicado. Chamar sobre um serviço construído com WithTx —
// o chamador é responsável por Commit/Rollback da transacção (para poder
// continuar, na mesma tx, com a lógica de negócio específica do módulo,
// ex.: pos.pos_payment_confirmations).
func (s *PaymentService) ProcessCallback(ctx context.Context, in CallbackInput) (CallbackResult, error) {
	var pi PaymentIntent
	err := s.db.QueryRow(ctx, `
		SELECT id, tenant_id, status, attempts
		  FROM integration.payment_intents
		 WHERE gateway_transaction_id = $1`,
		in.GatewayTransactionID,
	).Scan(&pi.ID, &pi.TenantID, &pi.Status, &pi.Attempts)
	if errors.Is(err, pgx.ErrNoRows) {
		return CallbackResult{}, ErrIntentNotFound
	}
	if err != nil {
		return CallbackResult{}, err
	}

	eventID := in.EventID
	if eventID == "" {
		eventID = callbackEventID(in)
	}
	var inboxID int64
	err = s.db.QueryRow(ctx, `
		INSERT INTO integration.inbox_events (source_service, event_id, event_type, tenant_id, payload)
		VALUES ('nexorapay', $1, 'payment.callback.v1', $2, $3)
		ON CONFLICT (source_service, event_id) DO NOTHING
		RETURNING id`,
		eventID, pi.TenantID, in.RawPayload,
	).Scan(&inboxID)
	if errors.Is(err, pgx.ErrNoRows) {
		return CallbackResult{Duplicate: true, Intent: &pi}, nil
	}
	if err != nil {
		return CallbackResult{}, err
	}

	switch {
	case in.Status == "succeeded" && in.TransactionStatus == "Completed":
		if err := s.finalizeIntent(ctx, pi.ID, IntentConfirmed, &in.GatewayTransactionID, in.RawPayload, ""); err != nil {
			return CallbackResult{}, err
		}
		pi.Status = IntentConfirmed
	case in.TransactionStatus == "Cancelled" || in.TransactionStatus == "Expired":
		if err := s.finalizeIntent(ctx, pi.ID, IntentFailed, &in.GatewayTransactionID, in.RawPayload, "pagamento cancelado ou expirado (callback)"); err != nil {
			return CallbackResult{}, err
		}
		pi.Status = IntentFailed
	}

	return CallbackResult{Intent: &pi}, nil
}

func callbackEventID(in CallbackInput) string {
	h := sha256.Sum256([]byte(in.GatewayTransactionID + "|" + in.Status + "|" + in.TransactionStatus))
	return hex.EncodeToString(h[:])
}

func extractGatewayError(resp map[string]any) string {
	if e, ok := resp["error"].(map[string]any); ok {
		if m, ok := e["message"].(string); ok && m != "" {
			return m
		}
	}
	return "Erro no gateway de pagamento"
}

func uniqueViolationConstraint(err error) string {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return pgErr.ConstraintName
	}
	return ""
}

func nonEmptyPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func nullIfEmpty(s string) any {
	if s == "" {
		return nil
	}
	return s
}

func nilIfEmptyBytes(b []byte) any {
	if len(b) == 0 {
		return nil
	}
	return b
}
