package adapters

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/modules/aprovacoes"
	"nexora/internal/shared/contracts"
)

// ApprovalAdapter implementa contracts.ApprovalPort reutilizando o
// pacote aprovacoes já existente no ERP.
type ApprovalAdapter struct {
	db *pgxpool.Pool
}

// NewApprovalAdapter cria um novo adaptador de Aprovações.
func NewApprovalAdapter(db *pgxpool.Pool) *ApprovalAdapter {
	return &ApprovalAdapter{db: db}
}

// NeedsApproval delega para aprovacoes.NeedsApproval().
func (a *ApprovalAdapter) NeedsApproval(ctx context.Context, tenantID int64, feature string, valor float64) (*contracts.ApprovalFlow, error) {
	flow, err := aprovacoes.NeedsApproval(ctx, a.db, tenantID, feature, valor)
	if err != nil || flow == nil {
		return nil, err
	}
	return &contracts.ApprovalFlow{
		ID:     flow.ID,
		Nome:   flow.Nome,
		Niveis: flow.Niveis,
	}, nil
}

// CreateRequest delega para aprovacoes.CreateRequest().
func (a *ApprovalAdapter) CreateRequest(ctx context.Context, tenantID, flowID, entidadeID, criadoPor int64, entidade string) error {
	return aprovacoes.CreateRequest(ctx, a.db, tenantID, flowID, entidadeID, criadoPor, entidade)
}
