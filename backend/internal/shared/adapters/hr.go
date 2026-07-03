package adapters

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// HRAdapter implementa contracts.HRPort.
type HRAdapter struct {
	db *pgxpool.Pool
}

// NewHRAdapter cria um novo adaptador do módulo RH.
func NewHRAdapter(db *pgxpool.Pool) *HRAdapter {
	return &HRAdapter{db: db}
}

// GetEmployeeID devolve o ID de rh.funcionarios para o user_id.
// Devolve 0 se não existir ou o módulo RH não estiver instalado.
func (a *HRAdapter) GetEmployeeID(ctx context.Context, tenantID, userID int64) (int64, error) {
	var id int64
	err := a.db.QueryRow(ctx, `
		SELECT f.id FROM rh.funcionarios f
		JOIN auth.users u ON u.email = f.email
		WHERE f.tenant_id = $1 AND u.id = $2 AND f.estado = 'ativo'
		LIMIT 1`, tenantID, userID).Scan(&id)
	if err == pgx.ErrNoRows {
		return 0, nil
	}
	return id, err
}

// CreateEmployee cria um funcionário em rh.funcionarios para um professor escolar.
// Idempotente por email — não duplica se já existir.
// Devolve o ID do funcionário criado (ou existente).
func (a *HRAdapter) CreateEmployee(ctx context.Context, e contracts.HREmployee) (int64, error) {
	if e.Nome == "" || e.TenantID == 0 {
		return 0, fmt.Errorf("nome e tenant_id obrigatórios para criar funcionário RH")
	}

	// Verificar se já existe por email
	if e.Email != "" {
		var existingID int64
		err := a.db.QueryRow(ctx, `
			SELECT id FROM rh.funcionarios
			WHERE tenant_id = $1 AND email = $2
			LIMIT 1`, e.TenantID, e.Email).Scan(&existingID)
		if err == nil {
			return existingID, nil // já existe
		}
	}

	var id int64
	err := a.db.QueryRow(ctx, `
		INSERT INTO rh.funcionarios
		(tenant_id, numero_funcionario, nome_completo, email, telefone, data_admissao, cargo, estado)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 'ativo')
		ON CONFLICT (tenant_id, numero_funcionario) WHERE numero_funcionario IS NOT NULL AND numero_funcionario <> '' DO UPDATE
		  SET email      = EXCLUDED.email,
		      updated_at = NOW()
		RETURNING id`,
		e.TenantID, e.NomeNumero, e.Nome, e.Email, e.Telefone, e.DataAdmissao, e.Cargo,
	).Scan(&id)
	return id, err
}
