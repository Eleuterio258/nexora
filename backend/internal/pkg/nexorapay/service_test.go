package nexorapay

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/pashagolub/pgxmock/v4"
)

func anyArgs(n int) []any {
	args := make([]any, n)
	for i := range args {
		args[i] = pgxmock.AnyArg()
	}
	return args
}

func TestInitiate_SucessoMarcaProcessingEGravaGatewayTxnID(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("Idempotency-Key"); got == "" {
			t.Error("Idempotency-Key em falta no pedido ao gateway")
		}
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"data":{"gatewayTransactionId":"gw-123","responseCode":"0"}}`))
	}))
	defer server.Close()

	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("INSERT INTO integration.payment_intents").
		WithArgs(anyArgs(12)...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectExec("UPDATE integration.payment_intents").
		WithArgs(anyArgs(5)...).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	svc := NewPaymentService(mock, NewClient(server.URL, "key", "pub"))
	intent, err := svc.Initiate(context.Background(), InitiateInput{
		TenantID: 1, SourceModule: "pos", Provider: "mpesa", MSISDN: "258840000000", Amount: 10, Moeda: "MZN",
	})
	if err != nil {
		t.Fatalf("Initiate: %v", err)
	}
	if intent.Status != IntentProcessing {
		t.Fatalf("Status = %q, want %q", intent.Status, IntentProcessing)
	}
	if intent.GatewayTransactionID == nil || *intent.GatewayTransactionID != "gw-123" {
		t.Fatalf("GatewayTransactionID = %v, want gw-123", intent.GatewayTransactionID)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestInitiate_ErroDeRedeMarcaUnknown(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Fecha a ligação sem responder, para o cliente HTTP falhar.
		hj, ok := w.(http.Hijacker)
		if !ok {
			t.Fatal("ResponseWriter não suporta Hijack")
		}
		conn, _, _ := hj.Hijack()
		conn.Close()
	}))
	defer server.Close()

	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("INSERT INTO integration.payment_intents").
		WithArgs(anyArgs(12)...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectExec("UPDATE integration.payment_intents").
		WithArgs(anyArgs(5)...).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	svc := NewPaymentService(mock, NewClient(server.URL, "key", "pub"))
	intent, err := svc.Initiate(context.Background(), InitiateInput{
		TenantID: 1, SourceModule: "pos", Provider: "mpesa", MSISDN: "258840000000", Amount: 10, Moeda: "MZN",
	})
	if err != nil {
		t.Fatalf("Initiate: %v", err)
	}
	if intent.Status != IntentUnknown {
		t.Fatalf("Status = %q, want %q", intent.Status, IntentUnknown)
	}
	if intent.Erro == nil {
		t.Fatal("Erro = nil, want mensagem do erro de rede")
	}
}

func TestInitiate_RejeicaoDoGatewayMarcaFailed(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnprocessableEntity)
		_, _ = w.Write([]byte(`{"error":{"message":"saldo insuficiente"}}`))
	}))
	defer server.Close()

	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("INSERT INTO integration.payment_intents").
		WithArgs(anyArgs(12)...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectExec("UPDATE integration.payment_intents").
		WithArgs(anyArgs(5)...).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	svc := NewPaymentService(mock, NewClient(server.URL, "key", "pub"))
	intent, err := svc.Initiate(context.Background(), InitiateInput{
		TenantID: 1, SourceModule: "pos", Provider: "mpesa", MSISDN: "258840000000", Amount: 10, Moeda: "MZN",
	})
	if err != nil {
		t.Fatalf("Initiate: %v", err)
	}
	if intent.Status != IntentFailed {
		t.Fatalf("Status = %q, want %q", intent.Status, IntentFailed)
	}
	if intent.Erro == nil || *intent.Erro != "saldo insuficiente" {
		t.Fatalf("Erro = %v, want \"saldo insuficiente\"", intent.Erro)
	}
}

// Um 2º pedido para a mesma referência (fluxo escolar) enquanto o 1º ainda
// está pending/processing/unknown não deve chamar o gateway outra vez —
// devolve o intent já existente, protegido pela constraint
// uq_payment_intents_active_reference.
func TestInitiate_ReferenciaJaActivaDevolveIntentExistenteSemChamarGateway(t *testing.T) {
	chamadasAoGateway := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		chamadasAoGateway++
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"data":{"gatewayTransactionId":"gw-999"}}`))
	}))
	defer server.Close()

	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("INSERT INTO integration.payment_intents").
		WithArgs(anyArgs(12)...).
		WillReturnError(&pgconn.PgError{Code: "23505", ConstraintName: "uq_payment_intents_active_reference"})
	mock.ExpectQuery("SELECT id, tenant_id, source_module, status").
		WithArgs(int64(1), "escolar", "school_fee", int64(42)).
		WillReturnRows(pgxmock.NewRows(
			[]string{"id", "tenant_id", "source_module", "status", "provider", "msisdn", "amount", "moeda", "gateway_transaction_id", "idempotency_key"},
		).AddRow("intent-existente", int64(1), "escolar", "processing", "mpesa", "258840000000", 50.0, "MZN", (*string)(nil), "intent-existente"))

	refID := int64(42)
	svc := NewPaymentService(mock, NewClient(server.URL, "key", "pub"))
	intent, err := svc.Initiate(context.Background(), InitiateInput{
		TenantID: 1, SourceModule: "escolar", ReferenceType: "school_fee", ReferenceID: &refID,
		Provider: "mpesa", MSISDN: "258840000000", Amount: 50, Moeda: "MZN",
	})
	if err != nil {
		t.Fatalf("Initiate: %v", err)
	}
	if intent.ID != "intent-existente" {
		t.Fatalf("ID = %q, want intent-existente (reencontrado, não criado)", intent.ID)
	}
	if chamadasAoGateway != 0 {
		t.Fatalf("chamadasAoGateway = %d, want 0 (não deve chamar o gateway para uma referência já activa)", chamadasAoGateway)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestClaimForReconciliation_ReservaSemMexerNoStatus(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("WITH candidatos AS").
		WithArgs(50, "worker-1").
		WillReturnRows(pgxmock.NewRows(
			[]string{"id", "tenant_id", "source_module", "status", "provider", "msisdn", "amount", "moeda", "gateway_transaction_id", "idempotency_key", "request_payload", "attempts"},
		).AddRow("intent-1", int64(1), "pos", "unknown", "mpesa", "258840000000", 10.0, "MZN", (*string)(nil), "intent-1", []byte(`{}`), 1))

	svc := NewPaymentService(mock, NewClient("http://example.invalid", "key", "pub"))
	intents, err := svc.ClaimForReconciliation(context.Background(), "worker-1", 50)
	if err != nil {
		t.Fatalf("ClaimForReconciliation: %v", err)
	}
	if len(intents) != 1 || intents[0].Status != "unknown" {
		t.Fatalf("intents = %+v, want 1 com status=unknown", intents)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestRecoverExpiredLeases(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE integration.payment_intents").
		WithArgs(pgxmock.AnyArg()).
		WillReturnResult(pgxmock.NewResult("UPDATE", 3))

	svc := NewPaymentService(mock, NewClient("http://example.invalid", "key", "pub"))
	n, err := svc.RecoverExpiredLeases(context.Background(), 5*time.Minute)
	if err != nil {
		t.Fatalf("RecoverExpiredLeases: %v", err)
	}
	if n != 3 {
		t.Fatalf("n = %d, want 3", n)
	}
}

func TestReconcile_ComGatewayTxnIDConhecidoConsultaEstado(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			t.Errorf("method = %s, want GET", r.Method)
		}
		_, _ = w.Write([]byte(`{"data":{"status":"succeeded","transactionStatus":"Completed"}}`))
	}))
	defer server.Close()

	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE integration.payment_intents").
		WithArgs(anyArgs(5)...).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	gwID := "gw-123"
	svc := NewPaymentService(mock, NewClient(server.URL, "key", "pub"))
	err = svc.Reconcile(context.Background(), PaymentIntent{ID: "intent-1", GatewayTransactionID: &gwID, Attempts: 1})
	if err != nil {
		t.Fatalf("Reconcile: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestReconcile_SemGatewayTxnIDReenviaPostComMesmaChave(t *testing.T) {
	var gotIdempotencyKey string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			t.Errorf("method = %s, want POST", r.Method)
		}
		gotIdempotencyKey = r.Header.Get("Idempotency-Key")
		w.WriteHeader(http.StatusCreated)
		_, _ = w.Write([]byte(`{"data":{"gatewayTransactionId":"gw-456"}}`))
	}))
	defer server.Close()

	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE integration.payment_intents").
		WithArgs(anyArgs(5)...).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	svc := NewPaymentService(mock, NewClient(server.URL, "key", "pub"))
	err = svc.Reconcile(context.Background(), PaymentIntent{
		ID: "intent-1", IdempotencyKey: "intent-1", RequestPayload: []byte(`{"amount":"10.00"}`),
	})
	if err != nil {
		t.Fatalf("Reconcile: %v", err)
	}
	if gotIdempotencyKey != "intent-1" {
		t.Fatalf("Idempotency-Key enviado = %q, want intent-1 (mesma chave do intent)", gotIdempotencyKey)
	}
}

func TestProcessCallback_EventoNovoConfirmaIntent(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("SELECT id, tenant_id, status, attempts").
		WithArgs("gw-123").
		WillReturnRows(pgxmock.NewRows([]string{"id", "tenant_id", "status", "attempts"}).
			AddRow("intent-1", int64(1), "processing", 0))
	mock.ExpectQuery("INSERT INTO integration.inbox_events").
		WithArgs(pgxmock.AnyArg(), int64(1), pgxmock.AnyArg()).
		WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow(int64(1)))
	mock.ExpectExec("UPDATE integration.payment_intents").
		WithArgs(anyArgs(5)...).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	svc := NewPaymentService(mock, NewClient("http://example.invalid", "key", "pub"))
	result, err := svc.ProcessCallback(context.Background(), CallbackInput{
		GatewayTransactionID: "gw-123", Status: "succeeded", TransactionStatus: "Completed",
		RawPayload: []byte(`{}`),
	})
	if err != nil {
		t.Fatalf("ProcessCallback: %v", err)
	}
	if result.Duplicate {
		t.Fatal("Duplicate = true, want false")
	}
	if result.Intent.Status != IntentConfirmed {
		t.Fatalf("Intent.Status = %q, want %q", result.Intent.Status, IntentConfirmed)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestProcessCallback_EventoRepetidoDeduplicaSemTocarNoIntent(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("SELECT id, tenant_id, status, attempts").
		WithArgs("gw-123").
		WillReturnRows(pgxmock.NewRows([]string{"id", "tenant_id", "status", "attempts"}).
			AddRow("intent-1", int64(1), "confirmed", 0))
	mock.ExpectQuery("INSERT INTO integration.inbox_events").
		WithArgs(pgxmock.AnyArg(), int64(1), pgxmock.AnyArg()).
		WillReturnError(pgx.ErrNoRows)

	svc := NewPaymentService(mock, NewClient("http://example.invalid", "key", "pub"))
	result, err := svc.ProcessCallback(context.Background(), CallbackInput{
		GatewayTransactionID: "gw-123", Status: "succeeded", TransactionStatus: "Completed",
		RawPayload: []byte(`{}`),
	})
	if err != nil {
		t.Fatalf("ProcessCallback: %v", err)
	}
	if !result.Duplicate {
		t.Fatal("Duplicate = false, want true")
	}
	// Nenhum UPDATE esperado: se tivesse tentado, o mock devolvia erro de
	// chamada inesperada.
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestProcessCallback_GatewayTxnIDDesconhecidoDevolveErro(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("SELECT id, tenant_id, status, attempts").
		WithArgs("gw-desconhecido").
		WillReturnError(pgx.ErrNoRows)

	svc := NewPaymentService(mock, NewClient("http://example.invalid", "key", "pub"))
	_, err = svc.ProcessCallback(context.Background(), CallbackInput{GatewayTransactionID: "gw-desconhecido"})
	if !errors.Is(err, ErrIntentNotFound) {
		t.Fatalf("err = %v, want ErrIntentNotFound", err)
	}
}
