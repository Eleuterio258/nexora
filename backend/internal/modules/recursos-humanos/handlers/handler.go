package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/shared/contracts"
	"nexora/internal/storage"
)

type Handler struct {
	db          *pgxpool.Pool
	cfg         *config.Config
	storage     storage.Provider
	assiduidade *assiduidade.Service
	signature   contracts.SignaturePort
	legalAudit  contracts.LegalAuditPort
}

func New(db *pgxpool.Pool, cfg *config.Config, st storage.Provider, signature contracts.SignaturePort, legalAudit contracts.LegalAuditPort) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st, assiduidade: assiduidade.NewService(db), signature: signature, legalAudit: legalAudit}
}

func jsonOK(w http.ResponseWriter, v any, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func jsonErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func decodeJSON(r *http.Request, v any) error {
	return json.NewDecoder(r.Body).Decode(v)
}

func isUniqueViolation(err error) bool {
	if pgErr, ok := err.(*pgconn.PgError); ok {
		return pgErr.Code == "23505"
	}
	return false
}

// uniqueViolationConstraint devolve o nome da constraint/índice violado quando
// err for um erro de violação de unicidade (23505), ou "" caso contrário.
func uniqueViolationConstraint(err error) string {
	if pgErr, ok := err.(*pgconn.PgError); ok && pgErr.Code == "23505" {
		return pgErr.ConstraintName
	}
	return ""
}

// registarAprovacaoLegal grava em auditoria.audit_events uma decisão de
// aprovação/rejeição de RH (avaliações, correcções, justificações, férias,
// disciplinar). Não-bloqueante — chamar sempre depois de a decisão já ter
// sido comitada.
func (h *Handler) registarAprovacaoLegal(ctx context.Context, tenantID, userID int64, ip, action, entityType, entityID string) {
	if h.legalAudit == nil {
		return
	}
	actorID := userID
	h.legalAudit.RecordEvent(ctx, contracts.LegalAuditEvent{
		TenantID: tenantID, ActorUserID: &actorID, IPAddress: ip,
		ServiceName: "nexora-erp", ModuleName: "recursos-humanos", Action: action,
		EntityType: entityType, EntityID: entityID,
	})
}
