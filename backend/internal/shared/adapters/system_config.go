package adapters

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// SystemConfigAdapter implementa contracts.SystemConfigPort lendo/gravando
// em sistema_configuracao.settings.
type SystemConfigAdapter struct {
	db *pgxpool.Pool
}

// NewSystemConfigAdapter cria um novo adaptador de Sistema-Configuração.
func NewSystemConfigAdapter(db *pgxpool.Pool) *SystemConfigAdapter {
	return &SystemConfigAdapter{db: db}
}

// Get devolve o valor de uma configuração para o tenant. Devolve "" se não existir.
func (a *SystemConfigAdapter) Get(ctx context.Context, tenantID int64, chave string) (string, error) {
	var valor string
	err := a.db.QueryRow(ctx, `
		SELECT valor FROM sistema_configuracao.settings
		WHERE (tenant_id = $1 OR tenant_id IS NULL)
		  AND chave = $2
		ORDER BY tenant_id DESC NULLS LAST
		LIMIT 1`, tenantID, chave).Scan(&valor)
	if err == pgx.ErrNoRows {
		return "", nil
	}
	return valor, err
}

// Set grava ou actualiza uma configuração para o tenant.
func (a *SystemConfigAdapter) Set(ctx context.Context, tenantID int64, chave, valor string) error {
	_, err := a.db.Exec(ctx, `
		INSERT INTO sistema_configuracao.settings (tenant_id, chave, valor, escopo)
		VALUES ($1, $2, $3, 'tenant')
		ON CONFLICT (tenant_id, chave) DO UPDATE
		  SET valor = EXCLUDED.valor, updated_at = NOW()`,
		tenantID, chave, valor)
	return err
}
