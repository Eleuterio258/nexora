package handlers

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

// aplicarPermissoesTipo copia para auth.permissoes_diretas as permissões padrão
// definidas em auth.permissoes_tipo para o tipo do utilizador userID.
// Usa ON CONFLICT DO NOTHING para ser idempotente (pode ser chamada várias vezes).
func aplicarPermissoesTipo(ctx context.Context, db *pgxpool.Pool, userID int64) error {
	_, err := db.Exec(ctx, `
		INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
		SELECT $1, pt.modulo, pt.acao
		  FROM auth.permissoes_tipo pt
		  JOIN auth.users u ON u.tipo = pt.tipo
		 WHERE u.id = $1
		ON CONFLICT DO NOTHING`, userID)
	return err
}
