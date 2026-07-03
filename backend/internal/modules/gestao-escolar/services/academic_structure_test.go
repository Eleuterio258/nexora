package services

import (
	"context"
	"testing"

	"github.com/pashagolub/pgxmock/v4"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

func TestAcademicStructureService_CreateLevelInvalidData(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewAcademicStructureService(repositories.NewAcademicStructureRepository(mock))

	cases := []struct {
		name  string
		level models.Level
	}{
		{"empty tenant", models.Level{TenantID: 0, Codigo: "PRI", Nome: "Primario"}},
		{"empty code", models.Level{TenantID: 1, Codigo: "", Nome: "Primario"}},
		{"empty name", models.Level{TenantID: 1, Codigo: "PRI", Nome: ""}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := svc.CreateLevel(context.Background(), &tc.level); err != ErrAcademicInvalidData {
				t.Fatalf("expected ErrAcademicInvalidData, got %v", err)
			}
		})
	}
}

func TestAcademicStructureService_CreateLevelDefaults(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("INSERT INTO gestao_escolar.school_levels").
		WithArgs(int64(1), "PRI", "Primario", "", 0, 10.0, 20.0, "0-20", 3, "trimestre", "classe", (*int)(nil), (*int)(nil)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "codigo", "nome", "descricao", "ordem", "nota_minima_aprovacao",
			"escala_maxima", "sistema_avaliacao", "numero_periodos_padrao", "nomenclatura_periodo",
			"nomenclatura_serie", "idade_minima", "idade_maxima", "activo", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), "PRI", "Primario", "", 0, 10.0, 20.0, "0-20", 3, "trimestre", "classe", (*int)(nil), (*int)(nil), true, now(), now()))

	svc := NewAcademicStructureService(repositories.NewAcademicStructureRepository(mock))
	level := models.Level{TenantID: 1, Codigo: "PRI", Nome: "Primario"}

	if err := svc.CreateLevel(context.Background(), &level); err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if level.SistemaAvaliacao != "0-20" || level.NumeroPeriodosPadrao != 3 {
		t.Fatalf("defaults not applied: %+v", level)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
