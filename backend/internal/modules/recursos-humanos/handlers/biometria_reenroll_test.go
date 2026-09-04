package handlers

import (
	"context"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/pashagolub/pgxmock/v4"
)

// beginTx abre uma transacção sobre o pool mockado, tal como
// h.db.Begin(r.Context()) no handler real — processReenrollWebhook recebe
// pgx.Tx directamente, por isso não precisa de um Handler/*pgxpool.Pool
// completo para ser testado (mesmo padrão de DBTX/NewServiceWithTx usado em
// internal/modules/recursos-humanos/service/assiduidade, Fase 0).
func beginTx(t *testing.T, mock pgxmock.PgxPoolIface) pgx.Tx {
	t.Helper()
	mock.ExpectBegin()
	tx, err := mock.Begin(context.Background())
	if err != nil {
		t.Fatalf("Begin: %v", err)
	}
	return tx
}

// Primeiro pedido com um event_id novo: grava inbox_events, auditoria e
// notificação — resultado não-duplicado e notificado.
func TestProcessReenrollWebhook_EventoNovoGravaTudo(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	tx := beginTx(t, mock)
	ctx := context.Background()

	mock.ExpectQuery("INSERT INTO integration.inbox_events").
		WithArgs("evt-1", int64(17), []byte(`{"x":1}`)).
		WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow(int64(1)))
	mock.ExpectExec("INSERT INTO auditoria.audit_logs").
		WithArgs(int64(17), int64(42), []byte(`{"x":1}`), "1.2.3.4").
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectQuery("INSERT INTO notif_colaborador").
		WithArgs(int64(17), int64(99)).
		WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow(int64(5)))
	mock.ExpectRollback()

	result, err := processReenrollWebhook(ctx, tx, reenrollWebhookInput{
		TenantID:      17,
		FuncionarioID: 42,
		ErpUserID:     99,
		EventID:       "evt-1",
		Detalhes:      []byte(`{"x":1}`),
		RemoteAddr:    "1.2.3.4",
	})
	if err != nil {
		t.Fatalf("processReenrollWebhook: %v", err)
	}
	if result.Duplicate {
		t.Fatal("Duplicate = true, want false")
	}
	if !result.Notified {
		t.Fatal("Notified = false, want true")
	}

	if err := tx.Rollback(ctx); err != nil {
		t.Fatalf("Rollback: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// Repetir o mesmo event_id (o worker do FaceClock reenviou o evento) não
// pode duplicar nem a auditoria nem a notificação — só o INSERT em
// inbox_events corre, com ON CONFLICT DO NOTHING a devolver zero linhas.
func TestProcessReenrollWebhook_EventoDuplicadoNaoRepeteAuditoriaNemNotificacao(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	tx := beginTx(t, mock)
	ctx := context.Background()

	mock.ExpectQuery("INSERT INTO integration.inbox_events").
		WithArgs("evt-1", int64(17), []byte(`{"x":1}`)).
		WillReturnError(pgx.ErrNoRows)
	mock.ExpectRollback()

	result, err := processReenrollWebhook(ctx, tx, reenrollWebhookInput{
		TenantID:      17,
		FuncionarioID: 42,
		ErpUserID:     99,
		EventID:       "evt-1",
		Detalhes:      []byte(`{"x":1}`),
		RemoteAddr:    "1.2.3.4",
	})
	if err != nil {
		t.Fatalf("processReenrollWebhook: %v", err)
	}
	if !result.Duplicate {
		t.Fatal("Duplicate = false, want true")
	}
	if result.Notified {
		t.Fatal("Notified = true, want false (nao deve notificar em duplicado)")
	}

	if err := tx.Rollback(ctx); err != nil {
		t.Fatalf("Rollback: %v", err)
	}
	// Nao ha ExpectExec/ExpectQuery para audit_logs/notif_colaborador: se o
	// codigo os tivesse chamado, o mock devolvia erro de expectativa nao
	// encontrada e o teste falhava em processReenrollWebhook acima.
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// Sem event_id (chamador antigo, ou algo fora do caminho do worker do
// outbox), preserva o comportamento anterior à Fase 1: sem inbox_events, só
// auditoria + WHERE NOT EXISTS em notif_colaborador.
func TestProcessReenrollWebhook_SemEventIDPreservaComportamentoAnterior(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	tx := beginTx(t, mock)
	ctx := context.Background()

	mock.ExpectExec("INSERT INTO auditoria.audit_logs").
		WithArgs(int64(17), int64(42), []byte(`{"x":1}`), "1.2.3.4").
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectQuery("INSERT INTO notif_colaborador").
		WithArgs(int64(17), int64(99)).
		WillReturnError(pgx.ErrNoRows)
	mock.ExpectRollback()

	result, err := processReenrollWebhook(ctx, tx, reenrollWebhookInput{
		TenantID:      17,
		FuncionarioID: 42,
		ErpUserID:     99,
		EventID:       "",
		Detalhes:      []byte(`{"x":1}`),
		RemoteAddr:    "1.2.3.4",
	})
	if err != nil {
		t.Fatalf("processReenrollWebhook: %v", err)
	}
	if result.Duplicate {
		t.Fatal("Duplicate = true, want false")
	}
	// Zero linhas em notif_colaborador (ErrNoRows) significa "ja existia um
	// aviso por ler" — nao e erro, mas tambem nao e uma nova notificacao.
	if result.Notified {
		t.Fatal("Notified = true, want false quando ja existia aviso por ler")
	}

	if err := tx.Rollback(ctx); err != nil {
		t.Fatalf("Rollback: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}
