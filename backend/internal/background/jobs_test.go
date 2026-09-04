package background

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/pashagolub/pgxmock/v4"

	hardwareservice "nexora/internal/modules/hardware/service"
	"nexora/internal/pkg/nexorapay"
)

func TestNotificationBackoffFor(t *testing.T) {
	cases := []struct {
		attempts int
		want     time.Duration
	}{
		{1, 1 * time.Minute},
		{2, 5 * time.Minute},
		{6, 12 * time.Hour},
		{100, 12 * time.Hour}, // fica fixo no último valor da tabela
		{0, 1 * time.Minute},  // defensivo: nunca deve acontecer, mas não deve rebentar
	}
	for _, c := range cases {
		if got := notificationBackoffFor(c.attempts); got != c.want {
			t.Errorf("notificationBackoffFor(%d) = %v, want %v", c.attempts, got, c.want)
		}
	}
}

func TestNotificationBackoffFor_Cresce(t *testing.T) {
	anterior := time.Duration(0)
	for attempts := 1; attempts <= notificationMaxAttempts; attempts++ {
		atual := notificationBackoffFor(attempts)
		if atual <= anterior {
			t.Errorf("backoff não cresceu entre tentativa %d e %d: %v -> %v", attempts-1, attempts, anterior, atual)
		}
		anterior = atual
	}
}

func TestClaimPendingNotifications_ReservaMarcaProcessandoENaoRepeteALinha(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	ctx := context.Background()

	mock.ExpectQuery("WITH candidatos AS").
		WithArgs(50, "worker-1").
		WillReturnRows(pgxmock.NewRows(
			[]string{"id", "canal_tipo", "destinatario", "assunto", "corpo", "tentativas", "anexo_storage_key", "anexo_nome", "payload"},
		).AddRow(int64(1), "email", "a@example.com", "Assunto", "Corpo", 0, "", "", []byte(nil)))

	claims, err := claimPendingNotifications(ctx, mock, "worker-1", 50)
	if err != nil {
		t.Fatalf("claimPendingNotifications: %v", err)
	}
	if len(claims) != 1 || claims[0].id != 1 {
		t.Fatalf("claims = %+v, want 1 claim com id=1", claims)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestClaimPendingNotifications_SemLinhasDevolveVazio(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	ctx := context.Background()

	mock.ExpectQuery("WITH candidatos AS").
		WithArgs(50, "worker-1").
		WillReturnRows(pgxmock.NewRows(
			[]string{"id", "canal_tipo", "destinatario", "assunto", "corpo", "tentativas", "anexo_storage_key", "anexo_nome"},
		))

	claims, err := claimPendingNotifications(ctx, mock, "worker-1", 50)
	if err != nil {
		t.Fatalf("claimPendingNotifications: %v", err)
	}
	if len(claims) != 0 {
		t.Fatalf("claims = %+v, want vazio", claims)
	}
}

func TestRecoverExpiredNotificationLeases_Loga(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	ctx := context.Background()

	mock.ExpectExec("UPDATE notifications.notification_messages").
		WithArgs(notificationLeaseTimeout.Seconds()).
		WillReturnResult(pgxmock.NewResult("UPDATE", 2))

	// Não há resultado a inspeccionar (a função só loga); confirma que corre
	// sem erro e que a query/params batem certo com o mock.
	recoverExpiredNotificationLeases(ctx, mock, notificationLeaseTimeout)

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestFinalizeNotification_SucessoMarcaEnviado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	ctx := context.Background()

	m := notificationClaim{id: 1, tentativas: 0}

	mock.ExpectExec("UPDATE notifications.notification_messages\\s+SET status='enviado'").
		WithArgs(1, int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	finalizeNotification(ctx, mock, m, nil)

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestFinalizeNotification_FalhaComTentativasDisponiveisAgendaRetry(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	ctx := context.Background()

	m := notificationClaim{id: 1, tentativas: 1} // 2ª tentativa < notificationMaxAttempts (6)

	mock.ExpectExec("UPDATE notifications.notification_messages\\s+SET status='pendente'").
		WithArgs(2, "falha de rede", notificationBackoffFor(2).Seconds(), int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	finalizeNotification(ctx, mock, m, errors.New("falha de rede"))

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestFinalizeNotification_FalhaComTentativasEsgotadasMarcaDeadLetter(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()
	ctx := context.Background()

	m := notificationClaim{id: 1, tentativas: notificationMaxAttempts - 1} // última tentativa possível

	mock.ExpectExec("UPDATE notifications.notification_messages\\s+SET status='falha'").
		WithArgs(notificationMaxAttempts, "falha permanente", int64(1)).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	finalizeNotification(ctx, mock, m, errors.New("falha permanente"))

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// stubPushSender substitui *push.Service nos testes do dispatcher — Fase 3
// de docs/analise-transactional-outbox-backends.md.
type stubPushSender struct {
	enabled bool
	calls   []stubPushCall
	err     error
}

type stubPushCall struct {
	token, title, body string
	data               map[string]string
}

func (s *stubPushSender) Enabled() bool { return s.enabled }

func (s *stubPushSender) SendOne(ctx context.Context, token, title, body string, data map[string]string) error {
	s.calls = append(s.calls, stubPushCall{token, title, body, data})
	return s.err
}

func TestDispatchNotifications_CanalPushChamaSendOneComPayload(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("UPDATE notifications.notification_messages").
		WithArgs(pgxmock.AnyArg()).
		WillReturnResult(pgxmock.NewResult("UPDATE", 0))

	mock.ExpectQuery("WITH candidatos AS").
		WithArgs(pgxmock.AnyArg(), "worker-1").
		WillReturnRows(pgxmock.NewRows(
			[]string{"id", "canal_tipo", "destinatario", "assunto", "corpo", "tentativas", "anexo_storage_key", "anexo_nome", "payload"},
		).AddRow(int64(7), "push", "token-abc", "Título", "Corpo", 0, "", "", []byte(`{"tipo":"venda_criada"}`)))

	mock.ExpectExec("UPDATE notifications.notification_messages").
		WithArgs(pgxmock.AnyArg(), pgxmock.AnyArg()).
		WillReturnResult(pgxmock.NewResult("UPDATE", 1))

	pushSvc := &stubPushSender{enabled: true}
	dispatchNotifications(mock, &sesMailer{}, nil, pushSvc, nil, "worker-1")

	if len(pushSvc.calls) != 1 {
		t.Fatalf("SendOne chamado %d vezes, want 1", len(pushSvc.calls))
	}
	call := pushSvc.calls[0]
	if call.token != "token-abc" || call.title != "Título" || call.body != "Corpo" {
		t.Fatalf("call = %+v, valores inesperados", call)
	}
	if call.data["tipo"] != "venda_criada" {
		t.Fatalf("data = %+v, want tipo=venda_criada", call.data)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestDispatchNotifications_SemCanalNenhumHabilitadoNaoFazNada(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	pushSvc := &stubPushSender{enabled: false}
	// Nenhuma expectativa registada: se o dispatcher tentasse tocar na BD, o
	// mock devolvia erro de chamada inesperada.
	dispatchNotifications(mock, &sesMailer{}, nil, pushSvc, nil, "worker-1")

	if len(pushSvc.calls) != 0 {
		t.Fatalf("SendOne não devia ter sido chamado")
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// stubPaymentReconciler substitui *nexorapay.PaymentService no teste do job
// de reconciliação — Fase 4 de docs/analise-transactional-outbox-backends.md.
type stubPaymentReconciler struct {
	claimed      []nexorapay.PaymentIntent
	reconciled   []string
	claimErr     error
	reconcileErr error
}

func (s *stubPaymentReconciler) RecoverExpiredLeases(ctx context.Context, leaseTimeout time.Duration) (int64, error) {
	return 0, nil
}

func (s *stubPaymentReconciler) ClaimForReconciliation(ctx context.Context, workerID string, limit int) ([]nexorapay.PaymentIntent, error) {
	if s.claimErr != nil {
		return nil, s.claimErr
	}
	return s.claimed, nil
}

func (s *stubPaymentReconciler) Reconcile(ctx context.Context, intent nexorapay.PaymentIntent) error {
	s.reconciled = append(s.reconciled, intent.ID)
	return s.reconcileErr
}

func TestReconcilePaymentIntents_ReconciliaCadaIntentReservado(t *testing.T) {
	svc := &stubPaymentReconciler{
		claimed: []nexorapay.PaymentIntent{{ID: "intent-1"}, {ID: "intent-2"}},
	}
	reconcilePaymentIntents(svc, "worker-1")

	if len(svc.reconciled) != 2 || svc.reconciled[0] != "intent-1" || svc.reconciled[1] != "intent-2" {
		t.Fatalf("reconciled = %v, want [intent-1 intent-2]", svc.reconciled)
	}
}

func TestReconcilePaymentIntents_ErroAoReservarNaoTentaReconciliar(t *testing.T) {
	svc := &stubPaymentReconciler{claimErr: errors.New("falha de ligação")}
	reconcilePaymentIntents(svc, "worker-1")

	if len(svc.reconciled) != 0 {
		t.Fatalf("reconciled = %v, want vazio (claim falhou)", svc.reconciled)
	}
}

// stubHardwareRetrier substitui *hardware/service.Processor no teste do job
// de retry — Fase 5 de docs/analise-transactional-outbox-backends.md.
type stubHardwareRetrier struct {
	claimed  []hardwareservice.DeviceEventRetry
	retried  []int64
	claimErr error
	retryErr error
}

func (s *stubHardwareRetrier) RecoverExpiredLeases(ctx context.Context, leaseTimeout time.Duration) (int64, error) {
	return 0, nil
}

func (s *stubHardwareRetrier) ClaimForRetry(ctx context.Context, workerID string, limit int) ([]hardwareservice.DeviceEventRetry, error) {
	if s.claimErr != nil {
		return nil, s.claimErr
	}
	return s.claimed, nil
}

func (s *stubHardwareRetrier) Retry(ctx context.Context, ev hardwareservice.DeviceEventRetry) error {
	s.retried = append(s.retried, ev.ID)
	return s.retryErr
}

func TestRetryHardwareEvents_TentaCadaEventoReservado(t *testing.T) {
	p := &stubHardwareRetrier{
		claimed: []hardwareservice.DeviceEventRetry{{ID: 1}, {ID: 2}},
	}
	retryHardwareEvents(p, "worker-1")

	if len(p.retried) != 2 || p.retried[0] != 1 || p.retried[1] != 2 {
		t.Fatalf("retried = %v, want [1 2]", p.retried)
	}
}

func TestRetryHardwareEvents_ErroAoReservarNaoTentaReprocessar(t *testing.T) {
	p := &stubHardwareRetrier{claimErr: errors.New("falha de ligação")}
	retryHardwareEvents(p, "worker-1")

	if len(p.retried) != 0 {
		t.Fatalf("retried = %v, want vazio (claim falhou)", p.retried)
	}
}
