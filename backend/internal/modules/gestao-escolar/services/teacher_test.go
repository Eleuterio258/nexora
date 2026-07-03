package services

import (
	"context"
	"testing"
	"time"

	"github.com/pashagolub/pgxmock/v4"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

func now() time.Time {
	return time.Now()
}

func TestTeacherService_CreateInvalidData(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewTeacherService(repositories.NewTeacherRepository(mock))

	cases := []struct {
		name    string
		teacher models.Teacher
	}{
		{"empty tenant", models.Teacher{TenantID: 0, Codigo: "T001", NomeCompleto: "Joao"}},
		{"empty code", models.Teacher{TenantID: 1, Codigo: "", NomeCompleto: "Joao"}},
		{"empty name", models.Teacher{TenantID: 1, Codigo: "T001", NomeCompleto: ""}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := svc.Create(context.Background(), &tc.teacher); err != ErrTeacherInvalidData {
				t.Fatalf("expected ErrTeacherInvalidData, got %v", err)
			}
		})
	}
}

func TestTeacherService_CreateDuplicateCode(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("SELECT EXISTS").
		WithArgs("T001", int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(true))

	svc := NewTeacherService(repositories.NewTeacherRepository(mock))
	teacher := models.Teacher{TenantID: 1, Codigo: "T001", NomeCompleto: "Joao"}

	if err := svc.Create(context.Background(), &teacher); err != ErrTeacherCodeDuplicate {
		t.Fatalf("expected ErrTeacherCodeDuplicate, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestTeacherService_CreateSuccess(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	mock.ExpectQuery("SELECT EXISTS").
		WithArgs("T001", int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(false))

	mock.ExpectQuery("INSERT INTO gestao_escolar.school_teachers").
		WithArgs(int64(1), (*int64)(nil), "T001", "Joao Silva", "", "", "", "", "", 40, "activo").
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "user_id", "codigo", "nome_completo", "genero", "telefone", "email",
			"documento_identificacao", "especialidade", "carga_horaria_maxima_semanal", "status", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), (*int64)(nil), "T001", "Joao Silva", "", "", "", "", "", 40, "activo", now(), now()))

	svc := NewTeacherService(repositories.NewTeacherRepository(mock))
	teacher := models.Teacher{TenantID: 1, Codigo: "T001", NomeCompleto: "Joao Silva"}

	if err := svc.Create(context.Background(), &teacher); err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if teacher.Status != "activo" {
		t.Fatalf("expected status activo, got %s", teacher.Status)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
