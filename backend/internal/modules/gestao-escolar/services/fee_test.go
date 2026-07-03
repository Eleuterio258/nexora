package services

import (
	"context"
	"testing"
	"time"

	"github.com/pashagolub/pgxmock/v4"
	"nexora/internal/modules/gestao-escolar/repositories"
)

func TestFeeService_GenerateFromPlanInvalidData(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewFeeService(repositories.NewFeeRepository(mock), nil, nil, nil, nil)

	mock.ExpectQuery("SELECT id, tenant_id, school_year_id, codigo, nome, tipo, valor, moeda, periodicidade, dia_vencimento, classe_nivel, activo, created_at, updated_at").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "school_year_id", "codigo", "nome", "tipo", "valor", "moeda",
			"periodicidade", "dia_vencimento", "classe_nivel", "activo", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), (*int64)(nil), "PLAN1", "Plano", "propina", float64(1000), "MZN",
			"mensal", (*int)(nil), "", true, time.Now(), time.Now()))

	_, _, err = svc.GenerateFromPlan(context.Background(), 1, 1, "2026-01", nil)
	if err != ErrFeeInvalidData {
		t.Fatalf("expected ErrFeeInvalidData, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestFeeService_GenerateFromPlanAlreadyGenerated(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewFeeService(repositories.NewFeeRepository(mock), nil, nil, nil, nil)

	yearID := int64(10)
	mock.ExpectQuery("SELECT id, tenant_id, school_year_id, codigo, nome, tipo, valor, moeda, periodicidade, dia_vencimento, classe_nivel, activo, created_at, updated_at").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "school_year_id", "codigo", "nome", "tipo", "valor", "moeda",
			"periodicidade", "dia_vencimento", "classe_nivel", "activo", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), &yearID, "PLAN1", "Plano", "propina", float64(1000), "MZN",
			"mensal", (*int)(nil), "", true, time.Now(), time.Now()))

	mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM gestao_escolar.school_fee_generations").
		WithArgs(int64(1), "2026-01").
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(1))

	_, _, err = svc.GenerateFromPlan(context.Background(), 1, 1, "2026-01", nil)
	if err != ErrFeeAlreadyGenerated {
		t.Fatalf("expected ErrFeeAlreadyGenerated, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
