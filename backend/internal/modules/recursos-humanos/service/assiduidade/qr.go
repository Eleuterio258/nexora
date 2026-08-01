package assiduidade

import (
	"context"
	"errors"
	"time"
)

// QRTokenValidado representa o resultado da validação de um QR token.
type QRTokenValidado struct {
	TokenID       int64
	LocationID    *string
	FuncionarioID *int64
	EmployeeNo    *string
}

// ErrQRInvalido, ErrQRExpirado e ErrQRUsado são os erros devolvidos pela
// validação de QR tokens.
var (
	ErrQRInvalido = errors.New("QR Code inválido")
	ErrQRExpirado = errors.New("QR Code expirado")
	ErrQRUsado    = errors.New("QR Code já utilizado")
)

// ValidarEUsarQRToken valida um token de QR (não expirado, não usado,
// pertencente ao tenant) e marca-o como usado atomicamente. Devolve os dados
// associados ao token para o registo de assiduidade.
func (s *Service) ValidarEUsarQRToken(ctx context.Context, tenantID int64, token string) (*QRTokenValidado, error) {
	var result QRTokenValidado
	var expiresAt time.Time

	err := s.db.QueryRow(ctx, `
		SELECT t.id, t.location_id, t.funcionario_id, f.numero_funcionario, t.expires_at
		  FROM rh.qr_tokens t
		  LEFT JOIN rh.funcionarios f ON f.id = t.funcionario_id AND f.tenant_id = t.tenant_id
		 WHERE t.token = $1 AND t.tenant_id = $2`,
		token, tenantID,
	).Scan(&result.TokenID, &result.LocationID, &result.FuncionarioID, &result.EmployeeNo, &expiresAt)
	if err != nil {
		return nil, ErrQRInvalido
	}

	if time.Now().After(expiresAt) {
		return nil, ErrQRExpirado
	}

	tag, err := s.db.Exec(ctx, `
		UPDATE rh.qr_tokens SET used_at = NOW()
		 WHERE token = $1 AND tenant_id = $2 AND used_at IS NULL`,
		token, tenantID)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, ErrQRUsado
	}

	return &result, nil
}
