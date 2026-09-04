package handlers

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5"

	"nexora/internal/modules/recursos-humanos/service/assiduidade"
)

const (
	facialVerificationIssuer   = "faceclock"
	facialVerificationAudience = "nexora-facial-attendance"
)

var (
	errFacialProofMissing = errors.New("comprovativo facial em falta")
	errFacialProofInvalid = errors.New("comprovativo facial invalido ou expirado")
	errFacialProofUsed    = errors.New("comprovativo facial ja utilizado")
)

type facialVerificationClaims struct {
	TenantID        string  `json:"tid"`
	DeviceID        string  `json:"device_id"`
	Purpose         string  `json:"purpose"`
	ConfidenceScore float64 `json:"confidence_score"`
	LivenessScore   float64 `json:"liveness_score"`
	jwt.RegisteredClaims
}

// consumeFacialVerification valida a assinatura e os vinculos do comprovativo
// e grava o jti. A restricao UNIQUE impede replay concorrente entre replicas.
//
// db recebe a transacao do chamador: o comprovativo so fica definitivamente
// consumido se o commit dessa transacao incluir tambem o registo do ponto.
func (h *Handler) consumeFacialVerification(
	ctx context.Context,
	db assiduidade.DBTX,
	rawToken string,
	userID, tenantID int64,
	deviceID string,
) (*facialVerificationClaims, error) {
	claims, err := parseFacialVerification(
		rawToken, h.cfg.FacialVerificationSecret, userID, tenantID, deviceID,
	)
	if err != nil {
		return nil, err
	}

	var consumedJTI string
	err = db.QueryRow(ctx, `
		INSERT INTO rh.facial_verification_uses
		  (jti, tenant_id, user_id, device_id, expires_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (jti) DO NOTHING
		RETURNING jti`,
		claims.ID, tenantID, userID, deviceID, claims.ExpiresAt.Time,
	).Scan(&consumedJTI)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, errFacialProofUsed
	}
	if err != nil {
		return nil, fmt.Errorf("registar consumo do comprovativo: %w", err)
	}

	_, _ = db.Exec(ctx, `DELETE FROM rh.facial_verification_uses WHERE expires_at < $1`, time.Now().Add(-24*time.Hour))
	return claims, nil
}

func parseFacialVerification(
	rawToken, secret string,
	userID, tenantID int64,
	deviceID string,
) (*facialVerificationClaims, error) {
	if rawToken == "" || deviceID == "" {
		return nil, errFacialProofMissing
	}

	claims := &facialVerificationClaims{}
	token, err := jwt.ParseWithClaims(
		rawToken,
		claims,
		func(token *jwt.Token) (any, error) {
			if token.Method.Alg() != jwt.SigningMethodHS256.Alg() {
				return nil, fmt.Errorf("algoritmo inesperado")
			}
			return []byte(secret), nil
		},
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(facialVerificationIssuer),
		jwt.WithAudience(facialVerificationAudience),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
	)
	if err != nil || !token.Valid || claims.Purpose != "facial_attendance" ||
		claims.Subject != strconv.FormatInt(userID, 10) ||
		claims.TenantID != strconv.FormatInt(tenantID, 10) ||
		claims.DeviceID != deviceID || claims.ID == "" || claims.ExpiresAt == nil {
		return nil, errFacialProofInvalid
	}

	return claims, nil
}
