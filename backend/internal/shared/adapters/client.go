package adapters

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// ClientAdapter implementa contracts.ClientPort.
type ClientAdapter struct {
	db *pgxpool.Pool
}

// NewClientAdapter cria um novo adaptador do módulo Gestão de Clientes.
func NewClientAdapter(db *pgxpool.Pool) *ClientAdapter {
	return &ClientAdapter{db: db}
}

// GetClientID devolve o ID de clientes.customers pelo email.
// Devolve 0 se não existir ou módulo não instalado.
func (a *ClientAdapter) GetClientID(ctx context.Context, tenantID int64, email string) (int64, error) {
	if email == "" {
		return 0, nil
	}
	var id int64
	err := a.db.QueryRow(ctx, `
		SELECT id FROM clientes.customers
		WHERE tenant_id = $1 AND email = $2
		LIMIT 1`, tenantID, email).Scan(&id)
	if err == pgx.ErrNoRows {
		return 0, nil
	}
	return id, err
}

// CreateClient cria ou devolve um cliente existente (idempotente por email).
// Devolve o ID do cliente criado ou encontrado.
func (a *ClientAdapter) CreateClient(ctx context.Context, c contracts.ClientData) (int64, error) {
	if c.Nome == "" || c.TenantID == 0 {
		return 0, fmt.Errorf("nome e tenant_id obrigatórios para criar cliente")
	}

	// Verificar por email primeiro
	if c.Email != "" {
		id, _ := a.GetClientID(ctx, c.TenantID, c.Email)
		if id > 0 {
			return id, nil
		}
	}

	// Gerar código único baseado no nome (sem espaços, uppercase, 8 chars)
	codigo := strings.ToUpper(strings.ReplaceAll(c.Nome, " ", ""))
	if len(codigo) > 8 {
		codigo = codigo[:8]
	}
	codigo = fmt.Sprintf("%s-%d", codigo, c.TenantID%1000)

	var id int64
	err := a.db.QueryRow(ctx, `
		INSERT INTO clientes.customers
		(tenant_id, codigo, nome, email, telefone, nuit, estado)
		VALUES ($1, $2, $3, $4, $5, $6, 'ativo')
		ON CONFLICT (tenant_id, codigo) DO UPDATE
		  SET nome  = EXCLUDED.nome,
		      email = EXCLUDED.email
		RETURNING id`,
		c.TenantID, codigo, c.Nome, c.Email, c.Telefone, c.Nuit,
	).Scan(&id)
	return id, err
}
