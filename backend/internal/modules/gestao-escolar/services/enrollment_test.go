package services

import (
	"context"
	"testing"

	"github.com/pashagolub/pgxmock/v4"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

func TestEnrollmentService_CreateInvalidData(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewEnrollmentService(repositories.NewEnrollmentRepository(mock), repositories.NewClassRepository(mock))

	cases := []struct {
		name       string
		enrollment models.Enrollment
	}{
		{"empty tenant", models.Enrollment{TenantID: 0, StudentID: 1, ClassID: 1, Numero: "M001"}},
		{"empty student", models.Enrollment{TenantID: 1, StudentID: 0, ClassID: 1, Numero: "M001"}},
		{"empty class", models.Enrollment{TenantID: 1, StudentID: 1, ClassID: 0, Numero: "M001"}},
		{"empty number", models.Enrollment{TenantID: 1, StudentID: 1, ClassID: 1, Numero: ""}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := svc.Create(context.Background(), &tc.enrollment); err != ErrEnrollmentInvalidData {
				t.Fatalf("expected ErrEnrollmentInvalidData, got %v", err)
			}
		})
	}
}

func TestEnrollmentService_CreateDuplicateNumber(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewEnrollmentService(repositories.NewEnrollmentRepository(mock), repositories.NewClassRepository(mock))

	yearID := int64(10)
	mock.ExpectQuery("SELECT id, tenant_id").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "school_year_id", "level_id", "series_id", "course_id",
			"codigo", "nome", "nivel", "turma", "turno", "sala", "capacidade",
			"director_teacher_id", "horario", "activo", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), &yearID, (*int64)(nil), (*int64)(nil), (*int64)(nil),
			"T1", "Turma 1", "", "", "manha", "", 30, (*int64)(nil), []byte("[]"), true, now(), now()))

	mock.ExpectQuery("SELECT id, tenant_id").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "school_year_id", "level_id", "series_id", "course_id",
			"codigo", "nome", "nivel", "turma", "turno", "sala", "capacidade",
			"director_teacher_id", "horario", "activo", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), &yearID, (*int64)(nil), (*int64)(nil), (*int64)(nil),
			"T1", "Turma 1", "", "", "manha", "", 30, (*int64)(nil), []byte("[]"), true, now(), now()))

	mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM gestao_escolar.school_enrollments").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(1))

	mock.ExpectQuery("SELECT id, tenant_id").
		WithArgs(int64(1), int64(10), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "school_year_id", "student_id", "class_id", "numero", "data_matricula",
			"tipo", "status", "observacoes", "transferred_at", "cancelled_at", "created_by", "created_at", "updated_at",
		}))

	mock.ExpectQuery("SELECT EXISTS").
		WithArgs("M001", int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(true))

	enrollment := models.Enrollment{TenantID: 1, StudentID: 1, ClassID: 1, Numero: "M001"}
	if err := svc.Create(context.Background(), &enrollment); err != ErrEnrollmentDuplicateNum {
		t.Fatalf("expected ErrEnrollmentDuplicateNum, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
