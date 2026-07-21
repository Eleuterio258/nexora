package assiduidade

import (
	"context"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/pashagolub/pgxmock/v4"
)

func int64ptr(v int64) *int64 { return &v }

// ResolverRegra deve devolver a regra do âmbito mais específico (funcionário)
// mesmo quando existem regras menos específicas (cargo, empresa) também
// activas — "a mais específica vence".
func TestResolverRegra_MaisEspecificoVence(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)
	ctx := context.Background()

	mock.ExpectQuery("SELECT id, parametros FROM rh.tipos_regra").
		WithArgs("tolerancia_atraso").
		WillReturnRows(pgxmock.NewRows([]string{"id", "parametros"}).
			AddRow(int64(1), []byte(`{"minutos": {"default": 10}}`)))

	// Nível "funcionario": sem regra explícita.
	mock.ExpectQuery("SELECT valor FROM rh.regras_assiduidade").
		WithArgs(int64(9), int64(1), "funcionario", int64(42)).
		WillReturnError(pgx.ErrNoRows)

	// Nível "cargo": regra explícita (5 minutos) — deve vencer face ao
	// default e a qualquer regra mais genérica de empresa.
	mock.ExpectQuery("SELECT valor FROM rh.regras_assiduidade").
		WithArgs(int64(9), int64(1), "cargo", int64(3)).
		WillReturnRows(pgxmock.NewRows([]string{"valor"}).
			AddRow([]byte(`{"minutos": 5}`)))

	niveis := []NivelEscopo{
		{Ambito: "funcionario", EntidadeID: int64ptr(42)},
		{Ambito: "cargo", EntidadeID: int64ptr(3)},
		{Ambito: "empresa", EntidadeID: nil},
	}

	valor, err := svc.ResolverRegra(ctx, 9, "tolerancia_atraso", niveis)
	if err != nil {
		t.Fatalf("ResolverRegra error: %v", err)
	}
	if got := valor["minutos"]; got != float64(5) {
		t.Fatalf("minutos = %v, want 5 (regra de cargo deveria vencer)", got)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

// Quando nenhum nível tem regra explícita, ResolverRegra devolve os valores
// por omissão descritos em rh.tipos_regra.parametros.
func TestResolverRegra_SemRegraUsaDefault(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)
	ctx := context.Background()

	mock.ExpectQuery("SELECT id, parametros FROM rh.tipos_regra").
		WithArgs("tolerancia_atraso").
		WillReturnRows(pgxmock.NewRows([]string{"id", "parametros"}).
			AddRow(int64(1), []byte(`{"minutos": {"default": 10}}`)))

	mock.ExpectQuery("SELECT valor FROM rh.regras_assiduidade").
		WithArgs(int64(9), int64(1), "empresa").
		WillReturnError(pgx.ErrNoRows)

	niveis := []NivelEscopo{
		{Ambito: "empresa", EntidadeID: nil},
	}

	valor, err := svc.ResolverRegra(ctx, 9, "tolerancia_atraso", niveis)
	if err != nil {
		t.Fatalf("ResolverRegra error: %v", err)
	}
	if got := valor["minutos"]; got != float64(10) {
		t.Fatalf("minutos = %v, want 10 (default do tipo de regra)", got)
	}
}
