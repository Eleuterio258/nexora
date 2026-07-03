// Package audit fornece funções base para registo de ações sensíveis no schema auth.
// A lógica de bloqueio (MFA/IP allowlist) será adicionada numa fase posterior.
package audit

import (
	"context"
	"encoding/json"
	"net"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Entry representa uma entrada de audit log.
type Entry struct {
	UserID    int64
	TenantID  int64
	Acao      string
	Modulo    string
	Recurso   string
	RecursoID string
	IPAddress string
	UserAgent string
	Detalhes  map[string]any
}

// Log grava uma entrada em auth.audit_logs.
func Log(ctx context.Context, pool *pgxpool.Pool, e Entry) error {
	if pool == nil {
		return nil
	}

	detalhes, err := json.Marshal(e.Detalhes)
	if err != nil {
		detalhes = []byte("{}")
	}

	ip := net.ParseIP(e.IPAddress)
	var ipAddr any
	if ip != nil {
		ipAddr = ip
	} else {
		ipAddr = nil
	}

	_, err = pool.Exec(ctx, `
		INSERT INTO auth.audit_logs (user_id, tenant_id, acao, modulo, recurso, recurso_id, ip_address, user_agent, detalhes)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`, e.UserID, e.TenantID, e.Acao, e.Modulo, e.Recurso, e.RecursoID, ipAddr, e.UserAgent, detalhes)

	return err
}

// LogRequest é um helper que extrai IP e User-Agent do request.
func LogRequest(r *http.Request, pool *pgxpool.Pool, e Entry) error {
	e.IPAddress = r.RemoteAddr
	e.UserAgent = r.UserAgent()
	return Log(r.Context(), pool, e)
}
