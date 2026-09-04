// Package assiduidade contém o motor de domínio do sistema flexível de
// controlo de assiduidade: registo de eventos, resolução de regras
// configuráveis por âmbito e cálculo de resultados diários.
package assiduidade

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// DBTX é a interface mínima de acesso à BD usada por este serviço. Tanto
// *pgxpool.Pool como pgx.Tx a implementam.
type DBTX interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

// DB permanece como alias para os consumidores existentes. Código novo deve
// usar DBTX para explicitar que tanto o pool como pgx.Tx são suportados.
type DB = DBTX

var (
	_ DBTX = (*pgxpool.Pool)(nil)
	_ DBTX = (pgx.Tx)(nil)
)

// Service agrupa as operações do motor de assiduidade sobre o schema rh
// (rh.eventos_assiduidade, rh.regras_assiduidade, rh.resultados_diarios).
type Service struct {
	db DBTX
}

// NewService cria um novo motor de assiduidade.
func NewService(db DBTX) *Service {
	return &Service{db: db}
}

// NewServiceWithTx explicita que todas as operações do serviço participam da
// transação recebida. O serviço nunca executa Commit ou Rollback; a unidade de
// trabalho continua sob responsabilidade do chamador.
func NewServiceWithTx(tx pgx.Tx) *Service {
	return NewService(tx)
}

// txBeginner é implementado por *pgxpool.Pool e por qualquer DBTX equivalente
// (incluindo mocks de teste) capaz de abrir uma transação.
type txBeginner interface {
	Begin(ctx context.Context) (pgx.Tx, error)
}

// withTx garante que fn corre como uma única unidade de trabalho. Quando o
// serviço já participa da transação de um chamador (NewServiceWithTx), fn
// corre directamente sobre essa transação e o commit/rollback continuam a ser
// responsabilidade do chamador — withTx não abre uma segunda transação por
// cima. Quando o serviço opera sobre a pool (NewService), withTx abre e fecha
// a sua própria transação, para que as escritas feitas dentro de fn sejam
// atómicas entre si mesmo sem um chamador transacional (Fase 0, item 4 de
// docs/analise-transactional-outbox-backends.md).
func (s *Service) withTx(ctx context.Context, fn func(*Service) error) error {
	if _, jaEmTx := s.db.(pgx.Tx); jaEmTx {
		return fn(s)
	}

	beginner, ok := s.db.(txBeginner)
	if !ok {
		return fn(s)
	}

	tx, err := beginner.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if err := fn(NewServiceWithTx(tx)); err != nil {
		return err
	}
	return tx.Commit(ctx)
}
