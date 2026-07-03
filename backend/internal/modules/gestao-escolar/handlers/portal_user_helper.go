package handlers

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
)

// upsertPortalUser cria ou actualiza um registo em auth.users para aluno/encarregado.
// Se passwordHash for vazio, a senha existente não é sobrescrita (útil em convites).
func (h *Handler) upsertPortalUser(
	ctx context.Context,
	email, nome, telefone, passwordHash, userTipo string,
	ativo bool,
) (int64, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" {
		return 0, fmt.Errorf("email é obrigatório")
	}

	var userID int64
	var existingTipo string

	err := h.db.QueryRow(ctx, `
		SELECT id, tipo
		  FROM auth.users
		 WHERE LOWER(email) = LOWER($1)`,
		email,
	).Scan(&userID, &existingTipo)

	if err == nil {
		if existingTipo != userTipo {
			return 0, fmt.Errorf("email já associado a outro tipo de utilizador")
		}
		if passwordHash != "" {
			_, err = h.db.Exec(ctx, `
				UPDATE auth.users
				   SET password_hash = $1,
				       estado = $2,
				       email_verificado = true,
				       updated_at = NOW()
				 WHERE id = $3`,
				passwordHash, estadoFromAtivo(ativo), userID)
		} else {
			_, err = h.db.Exec(ctx, `
				UPDATE auth.users
				   SET estado = $1,
				       updated_at = NOW()
				 WHERE id = $2`,
				estadoFromAtivo(ativo), userID)
		}
		return userID, err
	}

	if !errors.Is(err, pgx.ErrNoRows) {
		return 0, err
	}

	err = h.db.QueryRow(ctx, `
		INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo)
		VALUES ($1, LOWER($2), $3, $4, $5, $6, $7)
		RETURNING id`,
		nome, email, passwordHash, telefone, estadoFromAtivo(ativo), ativo, userTipo,
	).Scan(&userID)
	return userID, err
}

// updatePortalUserPassword actualiza a senha de um utilizador existente.
func (h *Handler) updatePortalUserPassword(ctx context.Context, userID int64, passwordHash string) error {
	_, err := h.db.Exec(ctx, `
		UPDATE auth.users
		   SET password_hash = $1,
		       estado = 'ativo',
		       email_verificado = true,
		       updated_at = NOW()
		 WHERE id = $2`,
		passwordHash, userID)
	return err
}

// getPortalUserByEmail devolve id, tipo e estado de um utilizador pelo email.
func (h *Handler) getPortalUserByEmail(ctx context.Context, email string) (int64, string, string, error) {
	var userID int64
	var tipo, estado string
	err := h.db.QueryRow(ctx, `
		SELECT id, tipo, estado
		  FROM auth.users
		 WHERE LOWER(email) = LOWER($1)`,
		email,
	).Scan(&userID, &tipo, &estado)
	return userID, tipo, estado, err
}

func estadoFromAtivo(ativo bool) string {
	if ativo {
		return "ativo"
	}
	return "pendente"
}
