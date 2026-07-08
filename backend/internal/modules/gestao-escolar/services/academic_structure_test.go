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

func TestAcademicStructureService_UpdateLevelRejectsUnknownColumn(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewAcademicStructureService(repositories.NewAcademicStructureRepository(mock))

	// Um nome de campo fora da lista branca nunca deve chegar a ser interpolado
	// na query SQL — isto é uma regressão de protecção contra injecção de SQL
	// através dos nomes de coluna de um UPDATE dinâmico.
	fields := map[string]any{"tenant_id=999--": "x"}
	err = svc.UpdateLevel(context.Background(), 1, 1, fields)
	if err != ErrAcademicInvalidData {
		t.Fatalf("expected ErrAcademicInvalidData for unknown column, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestAcademicStructureService_CreateCycleInvalidData(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewAcademicStructureService(repositories.NewAcademicStructureRepository(mock))

	cases := []struct {
		name  string
		cycle models.Cycle
	}{
		{"empty tenant", models.Cycle{TenantID: 0, LevelID: 1, Codigo: "C1", Nome: "Ciclo 1"}},
		{"empty level", models.Cycle{TenantID: 1, LevelID: 0, Codigo: "C1", Nome: "Ciclo 1"}},
		{"empty code", models.Cycle{TenantID: 1, LevelID: 1, Codigo: "", Nome: "Ciclo 1"}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if err := svc.CreateCycle(context.Background(), &tc.cycle); err != ErrAcademicInvalidData {
				t.Fatalf("expected ErrAcademicInvalidData, got %v", err)
			}
		})
	}
}

func TestAcademicStructureService_CreateCourseSubjectRequiresScope(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewAcademicStructureService(repositories.NewAcademicStructureRepository(mock))

	// Sem course_id, level_id ou series_id não há âmbito para o item de currículo.
	cs := models.CourseSubject{TenantID: 1, SubjectID: 5}
	if err := svc.CreateCourseSubject(context.Background(), &cs); err != ErrAcademicInvalidData {
		t.Fatalf("expected ErrAcademicInvalidData, got %v", err)
	}
}

func TestAcademicStructureService_CreateCourseSubjectDefaultsComponente(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	levelID := int64(2)
	obrigatoria := true
	mock.ExpectQuery("INSERT INTO gestao_escolar.school_course_subjects").
		WithArgs(int64(1), (*int64)(nil), &levelID, (*int64)(nil), int64(5), &obrigatoria, (*int)(nil), "teorica").
		WillReturnRows(pgxmock.NewRows([]string{
			"id", "tenant_id", "course_id", "level_id", "series_id", "subject_id",
			"obrigatoria", "carga_horaria_semanal", "componente", "activo", "created_at",
		}).AddRow(int64(1), int64(1), (*int64)(nil), &levelID, (*int64)(nil), int64(5), &obrigatoria, (*int)(nil), "teorica", true, now()))

	svc := NewAcademicStructureService(repositories.NewAcademicStructureRepository(mock))
	cs := models.CourseSubject{TenantID: 1, LevelID: &levelID, SubjectID: 5}

	if err := svc.CreateCourseSubject(context.Background(), &cs); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
	if cs.Componente != "teorica" {
		t.Fatalf("default componente not applied: %+v", cs)
	}
	if cs.Obrigatoria == nil || !*cs.Obrigatoria {
		t.Fatalf("default obrigatoria=true not applied: %+v", cs)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
