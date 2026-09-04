package push

import (
	"context"
	"testing"

	"github.com/pashagolub/pgxmock/v4"

	"nexora/internal/shared/adapters"
)

func insertArgs() []any {
	args := make([]any, 11)
	for i := range args {
		args[i] = pgxmock.AnyArg()
	}
	return args
}

func TestEnqueueToUser_EnfileraUmaLinhaPorToken(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := &Service{db: mock, notif: adapters.NewNotificationAdapter(mock)}

	mock.ExpectQuery("SELECT token FROM notifications.push_tokens").
		WithArgs(int64(42)).
		WillReturnRows(pgxmock.NewRows([]string{"token"}).AddRow("token-1").AddRow("token-2"))
	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(insertArgs()...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(insertArgs()...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	n, err := svc.EnqueueToUser(context.Background(), 7, 42, "Título", "Corpo", map[string]string{"tipo": "x"})
	if err != nil {
		t.Fatalf("EnqueueToUser: %v", err)
	}
	if n != 2 {
		t.Fatalf("n = %d, want 2", n)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestEnqueueToUser_SemTokensNaoEnfileraNada(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := &Service{db: mock, notif: adapters.NewNotificationAdapter(mock)}

	mock.ExpectQuery("SELECT token FROM notifications.push_tokens").
		WithArgs(int64(42)).
		WillReturnRows(pgxmock.NewRows([]string{"token"}))

	n, err := svc.EnqueueToUser(context.Background(), 7, 42, "Título", "Corpo", nil)
	if err != nil {
		t.Fatalf("EnqueueToUser: %v", err)
	}
	if n != 0 {
		t.Fatalf("n = %d, want 0", n)
	}
	// Nenhum INSERT esperado: se tivesse tentado um, o mock falhava.
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestEnqueueToTenant_EnfileraUmaLinhaPorToken(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := &Service{db: mock, notif: adapters.NewNotificationAdapter(mock)}

	mock.ExpectQuery("SELECT DISTINCT pt.token").
		WithArgs(int64(7)).
		WillReturnRows(pgxmock.NewRows([]string{"token"}).AddRow("token-1"))
	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(insertArgs()...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	n, err := svc.EnqueueToTenant(context.Background(), 7, "Aviso geral", "Corpo", nil)
	if err != nil {
		t.Fatalf("EnqueueToTenant: %v", err)
	}
	if n != 1 {
		t.Fatalf("n = %d, want 1", n)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestEnqueueToUser_FalhaAoEnfileirarUmTokenNaoAbortaOsRestantes(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := &Service{db: mock, notif: adapters.NewNotificationAdapter(mock)}

	mock.ExpectQuery("SELECT token FROM notifications.push_tokens").
		WithArgs(int64(42)).
		WillReturnRows(pgxmock.NewRows([]string{"token"}).AddRow("token-1").AddRow("token-2"))
	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(insertArgs()...).
		WillReturnError(context.DeadlineExceeded)
	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(insertArgs()...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	n, err := svc.EnqueueToUser(context.Background(), 7, 42, "Título", "Corpo", nil)
	if err != nil {
		t.Fatalf("EnqueueToUser: %v", err)
	}
	if n != 1 {
		t.Fatalf("n = %d, want 1 (um dos dois tokens falhou a enfileirar)", n)
	}
}

func TestSendOne_SemClienteFCMDevolveErro(t *testing.T) {
	svc := &Service{}
	if err := svc.SendOne(context.Background(), "token", "Título", "Corpo", nil); err == nil {
		t.Fatal("SendOne err = nil, want erro (FCM não configurado)")
	}
}

func TestEnabled(t *testing.T) {
	var nilSvc *Service
	if nilSvc.Enabled() {
		t.Fatal("Enabled() num *Service nil devia ser false")
	}
	if (&Service{}).Enabled() {
		t.Fatal("Enabled() sem client FCM devia ser false")
	}
}
