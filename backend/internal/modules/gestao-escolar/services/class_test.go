package services

import (
	"context"
	"testing"

	"github.com/pashagolub/pgxmock/v4"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

func TestClassService_CreateInvalidData(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewClassService(repositories.NewClassRepository(mock))

	cases := []struct {
		name  string
		class models.Class
	}{
		{"empty tenant", models.Class{TenantID: 0, Codigo: "T1", Nome: "Turma 1", Nivel: "8ª Classe"}},
		{"empty code", models.Class{TenantID: 1, Codigo: "", Nome: "Turma 1", Nivel: "8ª Classe"}},
		{"empty name", models.Class{TenantID: 1, Codigo: "T1", Nome: "", Nivel: "8ª Classe"}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := svc.Create(context.Background(), &tc.class); err != ErrClassInvalidData {
				t.Fatalf("expected ErrClassInvalidData, got %v", err)
			}
		})
	}
}

func TestClassService_CheckCapacityFull(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewClassService(repositories.NewClassRepository(mock))

	mock.ExpectQuery("SELECT id, tenant_id").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "school_year_id", "level_id", "series_id", "course_id",
			"codigo", "nome", "nivel", "turma", "turno", "sala", "capacidade",
			"director_teacher_id", "horario", "activo", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), (*int64)(nil), (*int64)(nil), (*int64)(nil), (*int64)(nil),
			"T1", "Turma 1", "", "", "manha", "", 2, (*int64)(nil), []byte("[]"), true, now(), now()))

	mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM gestao_escolar.school_enrollments").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(2))

	if err := svc.CheckCapacity(context.Background(), 1, 1); err != ErrClassFull {
		t.Fatalf("expected ErrClassFull, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
