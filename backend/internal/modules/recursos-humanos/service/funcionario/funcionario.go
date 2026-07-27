// Package funcionario fornece resolução centralizada de identidade de funcionários.
//
// O objetivo é uniformizar a forma como os diferentes endpoints de assiduidade
// (hardware, RH, self-service, auth) identificam o mesmo funcionário. Todos os
// fluxos devem resolver para o identificador canónico interno: funcionario_id
// (rh.funcionarios.id).
package funcionario

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// DB é a interface mínima de pool de BD usada por este serviço — permite
// tanto *pgxpool.Pool em produção como pgxmock em testes.
type DB interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// Identity representa a identidade resolvida de um funcionário.
type Identity struct {
	ID              int64
	TenantID        int64
	UserID          *int64
	NumeroFuncionario *string
	Email           *string
	NomeCompleto    string
	Estado          string
}

// Service agrupa as operações de resolução de identidade de funcionários.
type Service struct {
	db DB
}

// NewService cria um novo serviço de resolução de funcionários.
func NewService(db DB) *Service {
	return &Service{db: db}
}

// ErrFuncionarioNaoEncontrado é devolvido quando nenhum funcionário corresponde
// ao critério de pesquisa.
var ErrFuncionarioNaoEncontrado = errors.New("funcionário não encontrado")

// ErrFuncionarioInativo é devolvido quando o funcionário existe mas não está ativo.
var ErrFuncionarioInativo = errors.New("funcionário inativo")

// baseColumns contém as colunas base usadas em todos os lookups.
const baseColumns = `
	f.id,
	f.tenant_id,
	f.user_id,
	f.numero_funcionario,
	f.email,
	f.nome_completo,
	f.estado
`

// PorID resolve um funcionário pelo seu ID interno (rh.funcionarios.id).
func (s *Service) PorID(ctx context.Context, tenantID, funcionarioID int64) (*Identity, error) {
	var f Identity
	err := s.db.QueryRow(ctx, `
		SELECT `+baseColumns+`
		  FROM rh.funcionarios f
		 WHERE f.tenant_id = $1 AND f.id = $2`,
		tenantID, funcionarioID,
	).Scan(&f.ID, &f.TenantID, &f.UserID, &f.NumeroFuncionario, &f.Email, &f.NomeCompleto, &f.Estado)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrFuncionarioNaoEncontrado
		}
		return nil, err
	}
	return &f, nil
}

// PorEmployeeNo resolve um funcionário pelo seu número de funcionário
// (rh.funcionarios.numero_funcionario). Usado pelos dispositivos de hardware.
func (s *Service) PorEmployeeNo(ctx context.Context, tenantID int64, employeeNo string) (*Identity, error) {
	employeeNo = strings.TrimSpace(employeeNo)
	if employeeNo == "" {
		return nil, ErrFuncionarioNaoEncontrado
	}

	var f Identity
	err := s.db.QueryRow(ctx, `
		SELECT `+baseColumns+`
		  FROM rh.funcionarios f
		 WHERE f.tenant_id = $1 AND f.numero_funcionario = $2`,
		tenantID, employeeNo,
	).Scan(&f.ID, &f.TenantID, &f.UserID, &f.NumeroFuncionario, &f.Email, &f.NomeCompleto, &f.Estado)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrFuncionarioNaoEncontrado
		}
		return nil, err
	}
	return &f, nil
}

// PorUserID resolve um funcionário pelo ID do utilizador (auth.users.id).
func (s *Service) PorUserID(ctx context.Context, tenantID, userID int64) (*Identity, error) {
	var f Identity
	err := s.db.QueryRow(ctx, `
		SELECT `+baseColumns+`
		  FROM rh.funcionarios f
		 WHERE f.tenant_id = $1 AND f.user_id = $2`,
		tenantID, userID,
	).Scan(&f.ID, &f.TenantID, &f.UserID, &f.NumeroFuncionario, &f.Email, &f.NomeCompleto, &f.Estado)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrFuncionarioNaoEncontrado
		}
		return nil, err
	}
	return &f, nil
}

// PorEmail resolve um funcionário pelo email (rh.funcionarios.email).
func (s *Service) PorEmail(ctx context.Context, tenantID int64, email string) (*Identity, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" {
		return nil, ErrFuncionarioNaoEncontrado
	}

	var f Identity
	err := s.db.QueryRow(ctx, `
		SELECT `+baseColumns+`
		  FROM rh.funcionarios f
		 WHERE f.tenant_id = $1 AND LOWER(f.email) = $2`,
		tenantID, email,
	).Scan(&f.ID, &f.TenantID, &f.UserID, &f.NumeroFuncionario, &f.Email, &f.NomeCompleto, &f.Estado)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrFuncionarioNaoEncontrado
		}
		return nil, err
	}
	return &f, nil
}

// VerificarAtivo devolve erro se o funcionário não estiver ativo.
func (f *Identity) VerificarAtivo() error {
	if f.Estado != "ativo" {
		return ErrFuncionarioInativo
	}
	return nil
}
