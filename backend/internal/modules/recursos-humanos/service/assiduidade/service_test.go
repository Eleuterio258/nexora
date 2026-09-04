package assiduidade

import (
	"context"
	"testing"

	"github.com/pashagolub/pgxmock/v4"
)

// Confirma que o serviço executa as queries através do pgx.Tx recebido. Este
// é o contrato necessário para agrupar prova, evento e auditoria numa única
// unidade de trabalho nos próximos passos da Fase 0.
func TestNewServiceWithTx_UsaTransacaoDoChamador(t *testing.T) {
	ctx := context.Background()
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectBegin()
	tx, err := mock.Begin(ctx)
	if err != nil {
		t.Fatalf("Begin: %v", err)
	}

	mock.ExpectQuery("FROM saas.feature_catalog").
		WithArgs(int64(17)).
		WillReturnRows(pgxmock.NewRows([]string{"activo", "configuracao"}).
			AddRow(true, []byte(`{"metodos":{"facial":{"ativo":false}}}`)))
	mock.ExpectRollback()

	svc := NewServiceWithTx(tx)
	if svc.MetodoActivo(ctx, 17, "facial") {
		t.Fatal("MetodoActivo = true, want false")
	}
	if err := tx.Rollback(ctx); err != nil {
		t.Fatalf("Rollback: %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestRegistarAuditoria_AceitaTransacaoDoChamador(t *testing.T) {
	ctx := context.Background()
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectBegin()
	tx, err := mock.Begin(ctx)
	if err != nil {
		t.Fatalf("Begin: %v", err)
	}

	auditArgs := make([]any, 14)
	for i := range auditArgs {
		auditArgs[i] = pgxmock.AnyArg()
	}
	mock.ExpectExec("INSERT INTO rh.auditoria_assiduidade").
		WithArgs(auditArgs...).
		WillReturnResult(pgxmock.NewResult("INSERT", 1))
	mock.ExpectRollback()

	err = RegistarAuditoria(ctx, tx, AuditoriaEntry{
		TenantID:  17,
		Tabela:    "eventos_assiduidade",
		RegistoID: 101,
		Operacao:  "INSERT",
	})
	if err != nil {
		t.Fatalf("RegistarAuditoria: %v", err)
	}
	if err := tx.Rollback(ctx); err != nil {
		t.Fatalf("Rollback: %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}
