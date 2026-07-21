// Package tenantid resolve a tradução entre os dois espaços de
// identificadores de tenant usados pelo backend: empresas.companies.id
// (usado por hardware.devices.tenant_id) e saas.tenants.id (usado por
// rh.*, gestao_escolar.* e pela generalidade dos módulos de negócio).
//
// Descoberto por teste manual em 2026-07-11: os dois espaços partilham o
// nome de coluna "tenant_id" em várias tabelas mas são IDs DIFERENTES (ex.:
// Enigma School tinha companies.id=7 mas saas.tenants.id=5). Antes desta
// função existir, gravar directamente com o tenant_id recebido do device
// produzia registos com o tenant_id errado sempre que as duas IDs
// divergissem. Esta implementação estava duplicada em
// hardware/service/processor.go e
// recursos-humanos/handlers/assiduidade_integracao.go — consolidada aqui.
package tenantid

import (
	"context"

	"github.com/jackc/pgx/v5"
)

// DB é a interface mínima necessária (permite *pgxpool.Pool ou pgxmock).
type DB interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// ResolveSaas traduz um empresas.companies.id para o saas.tenants.id
// correspondente.
func ResolveSaas(ctx context.Context, db DB, companyID int64) (int64, error) {
	var saasTenantID int64
	err := db.QueryRow(ctx,
		`SELECT tenant_id FROM empresas.companies WHERE id = $1`, companyID,
	).Scan(&saasTenantID)
	return saasTenantID, err
}
