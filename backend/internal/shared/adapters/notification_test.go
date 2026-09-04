package adapters

import (
	"context"
	"errors"
	"testing"

	"github.com/pashagolub/pgxmock/v4"

	"nexora/internal/shared/contracts"
)

func TestNotificationAdapter_Send_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(int64(1), "email", "aluno@example.com", "Assunto", "Corpo", (*int64)(nil), nil, (*int64)(nil), nil, nil, nil).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	a := NewNotificationAdapter(mock)
	err = a.Send(context.Background(), contracts.Notification{
		TenantID:     1,
		CanalTipo:    "email",
		Destinatario: "aluno@example.com",
		Assunto:      "Assunto",
		Corpo:        "Corpo",
	})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// O payload (usado por canal_tipo="push") é serializado e incluído no
// INSERT — Fase 3 de docs/analise-transactional-outbox-backends.md.
func TestNotificationAdapter_Send_ComPayload(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(int64(1), "push", "token-abc", "Título", "Corpo", (*int64)(nil), nil, (*int64)(nil), nil, nil,
			[]byte(`{"tipo":"venda_criada"}`)).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))

	a := NewNotificationAdapter(mock)
	err = a.Send(context.Background(), contracts.Notification{
		TenantID:     1,
		CanalTipo:    "push",
		Destinatario: "token-abc",
		Assunto:      "Título",
		Corpo:        "Corpo",
		Payload:      map[string]any{"tipo": "venda_criada"},
	})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// O erro do INSERT tem de subir para o chamador, não ficar só em log — é o
// próprio ponto da Fase 2 item 6.
func TestNotificationAdapter_Send_DevolveErroDoInsert(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WillReturnError(errors.New("ligação perdida"))

	a := NewNotificationAdapter(mock)
	err = a.Send(context.Background(), contracts.Notification{
		TenantID:     1,
		CanalTipo:    "email",
		Destinatario: "aluno@example.com",
		Corpo:        "Corpo",
	})
	if err == nil {
		t.Fatal("Send err = nil, want erro do INSERT")
	}
}

func TestNotificationAdapter_Send_SemDestinatarioOuCorpoNaoGrava(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	a := NewNotificationAdapter(mock)
	if err := a.Send(context.Background(), contracts.Notification{TenantID: 1, Corpo: "Corpo"}); err != nil {
		t.Fatalf("Send sem destinatario: %v", err)
	}
	if err := a.Send(context.Background(), contracts.Notification{TenantID: 1, Destinatario: "x@example.com"}); err != nil {
		t.Fatalf("Send sem corpo: %v", err)
	}
	// Nenhuma expectativa registada: se tivesse tentado o INSERT, o mock
	// devolvia erro de chamada inesperada e os Send() acima falhavam.
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// Confirma que Send participa da transacção do chamador quando o adaptador é
// criado com NewNotificationAdapterWithTx — mesmo contrato de
// assiduidade.NewServiceWithTx (Fase 0): nunca comita/reverte, só usa a tx.
func TestNewNotificationAdapterWithTx_UsaTransacaoDoChamador(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	ctx := context.Background()
	mock.ExpectBegin()
	tx, err := mock.Begin(ctx)
	if err != nil {
		t.Fatalf("Begin: %v", err)
	}

	insertArgs := make([]any, 11)
	for i := range insertArgs {
		insertArgs[i] = pgxmock.AnyArg()
	}
	mock.ExpectExec("INSERT INTO notifications.notification_messages").
		WithArgs(insertArgs...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectCommit()

	a := NewNotificationAdapterWithTx(tx)
	if err := a.Send(ctx, contracts.Notification{
		TenantID: 1, CanalTipo: "email", Destinatario: "aluno@example.com", Corpo: "Corpo",
	}); err != nil {
		t.Fatalf("Send: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("Commit: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}
