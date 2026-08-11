package adapters

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// LegalAuditAdapter implementa contracts.LegalAuditPort escrevendo em
// auditoria.audit_events, mantendo a cadeia de hash (event_hash encadeado
// com previous_hash) que dá a esta tabela o seu valor legal/imutável.
type LegalAuditAdapter struct {
	db *pgxpool.Pool
}

// NewLegalAuditAdapter cria um novo adaptador de auditoria legal.
func NewLegalAuditAdapter(db *pgxpool.Pool) *LegalAuditAdapter {
	return &LegalAuditAdapter{db: db}
}

// RecordEvent grava um evento legal, encadeando-o ao último evento do mesmo
// tenant via event_hash/previous_hash. Serializa por tenant com um advisory
// lock transaccional, para duas escritas concorrentes nunca calcularem o
// mesmo previous_hash. Não bloqueante por desenho — falhas ficam só em log;
// chamar sempre DEPOIS de a operação de negócio já ter sido comitada.
func (a *LegalAuditAdapter) RecordEvent(ctx context.Context, e contracts.LegalAuditEvent) error {
	status := e.Status
	if status == "" {
		status = "sucesso"
	}

	tx, err := a.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtext('audit_events:' || $1::text))`, e.TenantID); err != nil {
		return err
	}

	var previousHash string
	err = tx.QueryRow(ctx, `
		SELECT event_hash FROM auditoria.audit_events
		 WHERE tenant_id=$1 ORDER BY id DESC LIMIT 1`, e.TenantID).Scan(&previousHash)
	if err != nil {
		previousHash = "" // sem eventos anteriores para este tenant — normal
	}

	var actorEmail, actorNome string
	if e.ActorUserID != nil {
		if err := tx.QueryRow(ctx, `SELECT nome, email FROM auth.users WHERE id=$1`, *e.ActorUserID).
			Scan(&actorNome, &actorEmail); err != nil {
			log.Printf("[WARN] LegalAuditAdapter.RecordEvent: não foi possível obter nome/email do actor %d: %v", *e.ActorUserID, err)
		}
	}

	metadataJSON, _ := json.Marshal(e.Metadata)
	beforeJSON, _ := json.Marshal(e.PayloadBefore)
	afterJSON, _ := json.Marshal(e.PayloadAfter)

	eventHash := sha256.Sum256([]byte(fmt.Sprintf("%s|%d|%s|%s|%s|%s|%s|%s",
		previousHash, e.TenantID, e.ServiceName, e.ModuleName, e.Action, e.EntityType, e.EntityID, metadataJSON)))

	var newPreviousHash *string
	if previousHash != "" {
		newPreviousHash = &previousHash
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO auditoria.audit_events
		  (tenant_id, actor_user_id, actor_email, actor_nome, service_name, module_name,
		   action, entity_type, entity_id, status, ip_address, user_agent,
		   metadata, payload_before, payload_after, previous_hash, event_hash)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)`,
		e.TenantID, e.ActorUserID, nullIfEmpty(actorEmail), nullIfEmpty(actorNome), e.ServiceName, e.ModuleName,
		e.Action, e.EntityType, nullIfEmpty(e.EntityID), status, nullIfEmpty(e.IPAddress), nullIfEmpty(e.UserAgent),
		metadataJSON, beforeJSON, afterJSON, newPreviousHash, hex.EncodeToString(eventHash[:]),
	); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func nullIfEmpty(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
