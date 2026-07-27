package funcionario

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/pashagolub/pgxmock/v4"
)

func baseColumnsSlice() []string {
	return []string{"id", "tenant_id", "user_id", "numero_funcionario", "email", "nome_completo", "estado"}
}

func TestPorID_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)

	mock.ExpectQuery("SELECT .* FROM rh.funcionarios f").
		WithArgs(int64(1), int64(10)).
		WillReturnRows(pgxmock.NewRows(baseColumnsSlice()).
			AddRow(int64(10), int64(1), (*int64)(nil), (*string)(nil), (*string)(nil), "Ana Silva", "ativo"))

	f, err := svc.PorID(context.Background(), 1, 10)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if f.ID != 10 || f.NomeCompleto != "Ana Silva" {
		t.Fatalf("unexpected result: %+v", f)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("expectations not met: %v", err)
	}
}

func TestPorID_NaoEncontrado(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)

	mock.ExpectQuery("SELECT .* FROM rh.funcionarios f").
		WithArgs(int64(1), int64(10)).
		WillReturnError(pgx.ErrNoRows)

	_, err = svc.PorID(context.Background(), 1, 10)
	if !errors.Is(err, ErrFuncionarioNaoEncontrado) {
		t.Fatalf("expected ErrFuncionarioNaoEncontrado, got %v", err)
	}
}

func TestPorEmployeeNo_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)
	empNo := "FUNC001"

	mock.ExpectQuery("SELECT .* FROM rh.funcionarios f").
		WithArgs(int64(1), empNo).
		WillReturnRows(pgxmock.NewRows(baseColumnsSlice()).
			AddRow(int64(10), int64(1), (*int64)(nil), &empNo, (*string)(nil), "Ana Silva", "ativo"))

	f, err := svc.PorEmployeeNo(context.Background(), 1, empNo)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if f.NumeroFuncionario == nil || *f.NumeroFuncionario != empNo {
		t.Fatalf("unexpected employee_no: %+v", f)
	}
}

func TestPorEmployeeNo_Vazio(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)

	_, err = svc.PorEmployeeNo(context.Background(), 1, "  ")
	if !errors.Is(err, ErrFuncionarioNaoEncontrado) {
		t.Fatalf("expected ErrFuncionarioNaoEncontrado, got %v", err)
	}
}

func TestPorUserID_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)
	uid := int64(99)
	empNo := "FUNC001"

	mock.ExpectQuery("SELECT .* FROM rh.funcionarios f").
		WithArgs(int64(1), uid).
		WillReturnRows(pgxmock.NewRows(baseColumnsSlice()).
			AddRow(int64(10), int64(1), &uid, &empNo, (*string)(nil), "Ana Silva", "ativo"))

	f, err := svc.PorUserID(context.Background(), 1, uid)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if f.UserID == nil || *f.UserID != uid {
		t.Fatalf("unexpected user_id: %+v", f)
	}
}

func TestPorEmail_Sucesso(t *testing.T) {
	mock, err := pgxmock.NewPool()
	if err != nil {
		t.Fatal(err)
	}
	defer mock.Close()

	svc := NewService(mock)
	email := "ana@nexora.test"
	uid := int64(99)

	mock.ExpectQuery("SELECT .* FROM rh.funcionarios f").
		WithArgs(int64(1), "ana@nexora.test").
		WillReturnRows(pgxmock.NewRows(baseColumnsSlice()).
			AddRow(int64(10), int64(1), &uid, (*string)(nil), &email, "Ana Silva", "ativo"))

	f, err := svc.PorEmail(context.Background(), 1, email)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if f.Email == nil || *f.Email != email {
		t.Fatalf("unexpected email: %+v", f)
	}
}

func TestVerificarAtivo_Inativo(t *testing.T) {
	f := &Identity{Estado: "desligado"}
	if err := f.VerificarAtivo(); !errors.Is(err, ErrFuncionarioInativo) {
		t.Fatalf("expected ErrFuncionarioInativo, got %v", err)
	}
}
