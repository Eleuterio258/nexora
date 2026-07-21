// Package assiduidade contém o motor de domínio do sistema flexível de
// controlo de assiduidade: registo de eventos, resolução de regras
// configuráveis por âmbito e cálculo de resultados diários.
package assiduidade

import (
	"context"

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

// Service agrupa as operações do motor de assiduidade sobre o schema rh
// (rh.eventos_assiduidade, rh.regras_assiduidade, rh.resultados_diarios).
type Service struct {
	db DB
}

// NewService cria um novo motor de assiduidade.
func NewService(db DB) *Service {
	return &Service{db: db}
}
