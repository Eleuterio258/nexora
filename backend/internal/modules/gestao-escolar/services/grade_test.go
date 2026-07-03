package services

import (
	"context"
	"testing"
	"time"

	"github.com/pashagolub/pgxmock/v4"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

func TestGradeService_CreateItemInvalidData(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewGradeService(repositories.NewGradeRepository(mock))

	cases := []struct {
		name string
		item models.GradeItem
	}{
		{"empty tenant", models.GradeItem{TenantID: 0, ClassID: 1, SubjectID: 1, TermID: 1, Nome: "Teste"}},
		{"empty class", models.GradeItem{TenantID: 1, ClassID: 0, SubjectID: 1, TermID: 1, Nome: "Teste"}},
		{"empty subject", models.GradeItem{TenantID: 1, ClassID: 1, SubjectID: 0, TermID: 1, Nome: "Teste"}},
		{"empty term", models.GradeItem{TenantID: 1, ClassID: 1, SubjectID: 1, TermID: 0, Nome: "Teste"}},
		{"empty name", models.GradeItem{TenantID: 1, ClassID: 1, SubjectID: 1, TermID: 1, Nome: ""}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := svc.CreateItem(context.Background(), &tc.item); err != ErrGradeInvalidData {
				t.Fatalf("expected ErrGradeInvalidData, got %v", err)
			}
		})
	}
}

func TestGradeService_UpsertGradeOutOfRange(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewGradeService(repositories.NewGradeRepository(mock))

	mock.ExpectQuery("SELECT id, tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by, created_at, updated_at").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "class_id", "subject_id", "term_id", "nome", "tipo",
			"data_avaliacao", "nota_maxima", "peso", "publicado", "created_by", "created_at", "updated_at",
		}).AddRow(int64(1), int64(1), int64(1), int64(1), int64(1), "Teste", "teste",
			time.Now(), float64(20), float64(1), false, (*int64)(nil), now(), now()))

	grade := models.Grade{TenantID: 1, GradeItemID: 1, StudentID: 1, Nota: 25}
	if err := svc.UpsertGrade(context.Background(), &grade); err != ErrGradeOutOfRange {
		t.Fatalf("expected ErrGradeOutOfRange, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
