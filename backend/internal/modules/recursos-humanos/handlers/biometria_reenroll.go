package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/jackc/pgx/v5"

	mw "nexora/internal/middleware"
)

// ── Webhook de re-enrolamento biométrico (FaceClock → ERP) ──────────────────
//
// Quando o FaceClock detecta que o `model_version` de um template activo já
// não corresponde ao modelo em uso, marca-o como PENDING_REENROLL e chama este
// endpoint (ver `notify_reenroll_required` em app/erp_client.py). O template
// deixou de ser utilizável para verificação: o colaborador tem de repetir o
// enrolamento facial antes de conseguir marcar ponto por reconhecimento.
//
// A chamada do FaceClock é best-effort e nunca bloqueia o verify que a
// despoletou, por isso este endpoint é deliberadamente tolerante: responde 202
// mesmo quando não há nada de novo a notificar (aviso já pendente). O que
// interessa ao FaceClock é saber que a notificação foi aceite, não o que o ERP
// decidiu fazer com ela.
//
// Autenticado por RequireDeviceAuth (X-API-Key), como os restantes endpoints
// /api/hardware/assiduidade/*.

// reenrollRequiredRequest é o payload enviado por notify_reenroll_required.
//
// TenantID vem do ActorContext do FaceClock (String(36)) e é apenas
// informativo — quem manda no isolamento por tenant é o device autenticado,
// não o corpo do pedido. Fica registado em `detalhes` para permitir detectar
// credenciais Nexora mal provisionadas.
type reenrollRequiredRequest struct {
	ErpUserID       string `json:"erp_user_id"`
	TenantID        string `json:"tenant_id"`
	OldModelVersion string `json:"old_model_version"`
	NewModelVersion string `json:"new_model_version"`
	// EventID identifica o evento do outbox do FaceClock (Fase 1 de
	// docs/analise-transactional-outbox-backends.md). Opcional por
	// tolerância: sem ele, o pedido cai no comportamento anterior
	// (deduplicação só pelo `WHERE NOT EXISTS` de notif_colaborador).
	EventID string `json:"event_id"`
}

// POST /api/hardware/assiduidade/biometria/reenroll-required
//
// Regista o pedido de re-enrolamento em auditoria e cria um aviso ao
// colaborador em notif_colaborador.
func (h *Handler) NotificarReenrollDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body reenrollRequiredRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ErpUserID == "" {
		jsonErr(w, "erp_user_id é obrigatório", http.StatusBadRequest)
		return
	}
	if body.NewModelVersion == "" {
		jsonErr(w, "new_model_version é obrigatório", http.StatusBadRequest)
		return
	}
	// erp_user_id é auth.users.id (ver lgpd_consentimentos.go). O FaceClock
	// envia-o como string; converte-se aqui porque notif_colaborador.user_id
	// é bigint.
	erpUserID, err := strconv.ParseInt(body.ErpUserID, 10, 64)
	if err != nil || erpUserID <= 0 {
		jsonErr(w, "erp_user_id inválido", http.StatusBadRequest)
		return
	}

	funcionarioID, ok := h.resolverFuncionarioPorUserID(r, body.ErpUserID, tenantID)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	device := mw.GetDevice(r)
	detalhes, _ := json.Marshal(map[string]any{
		"erp_user_id":         erpUserID,
		"old_model_version":   body.OldModelVersion,
		"new_model_version":   body.NewModelVersion,
		"faceclock_tenant_id": body.TenantID,
		"device_id":           device.ID,
		"device_nome":         device.Nome,
	})

	// Inbox + auditoria + aviso ao colaborador entram na mesma transação: um
	// webhook aceite tem de deixar todas as linhas gravadas, ou nenhuma —
	// nunca uma auditoria órfã sem o aviso correspondente (Fase 0, item 5), e
	// nunca uma duplicação de ambas quando o worker do outbox reenvia o
	// mesmo evento (Fase 1, item 6, de
	// docs/analise-transactional-outbox-backends.md).
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	result, err := processReenrollWebhook(r.Context(), tx, reenrollWebhookInput{
		TenantID:      tenantID,
		FuncionarioID: funcionarioID,
		ErpUserID:     erpUserID,
		EventID:       body.EventID,
		Detalhes:      detalhes,
		RemoteAddr:    r.RemoteAddr,
	})
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"funcionario_id": funcionarioID,
		"event_id":       body.EventID,
		"duplicate":      result.Duplicate,
		"notificado":     result.Notified,
	}, http.StatusAccepted)
}

// reenrollWebhookInput agrupa os dados já validados/resolvidos pelo handler
// (tenant do device, funcionário, corpo do pedido) que processReenrollWebhook
// precisa para gravar inbox + auditoria + aviso.
type reenrollWebhookInput struct {
	TenantID      int64
	FuncionarioID int64
	ErpUserID     int64
	EventID       string
	Detalhes      []byte
	RemoteAddr    string
}

type reenrollWebhookResult struct {
	Duplicate bool
	Notified  bool
}

// processReenrollWebhook grava, numa única unidade de trabalho, a
// deduplicação por event_id (integration.inbox_events), a auditoria
// (auditoria.audit_logs) e o aviso ao colaborador (notif_colaborador).
// Recebe pgx.Tx directamente (não *pgxpool.Pool) para poder ser testado com
// pgxmock sem precisar de um Handler completo — mesmo padrão de
// internal/modules/recursos-humanos/service/assiduidade (DBTX/NewServiceWithTx,
// Fase 0).
func processReenrollWebhook(ctx context.Context, tx pgx.Tx, in reenrollWebhookInput) (reenrollWebhookResult, error) {
	// Deduplicação forte por event_id: um evento já visto (mesmo
	// source_service+event_id) não repete auditoria nem notificação, por
	// mais vezes que o worker do FaceClock o reenvie. TenantID já vem do
	// device autenticado (resolveSaasTenantID), nunca do corpo do pedido —
	// mesma garantia já aplicada a FuncionarioID.
	if in.EventID != "" {
		var inboxID int64
		err := tx.QueryRow(ctx, `
			INSERT INTO integration.inbox_events (source_service, event_id, event_type, tenant_id, payload)
			VALUES ('faceclock', $1, 'biometric.reenroll_required.v1', $2, $3)
			ON CONFLICT (source_service, event_id) DO NOTHING
			RETURNING id`,
			in.EventID, in.TenantID, in.Detalhes,
		).Scan(&inboxID)
		if errors.Is(err, pgx.ErrNoRows) {
			return reenrollWebhookResult{Duplicate: true}, nil
		}
		if err != nil {
			return reenrollWebhookResult{}, err
		}
	}

	// user_id fica NULL: o actor é um dispositivo, não uma conta de
	// utilizador, e audit_logs.user_id é lido/indexado como auth.users.id. A
	// identificação do dispositivo vai em `detalhes`.
	if _, err := tx.Exec(ctx, `
		INSERT INTO auditoria.audit_logs (tenant_id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address)
		VALUES ($1, NULL, 'recursos-humanos', 'biometria_facial', $2, 'reenroll_required', $3, $4)`,
		in.TenantID, in.FuncionarioID, in.Detalhes, in.RemoteAddr,
	); err != nil {
		return reenrollWebhookResult{}, err
	}

	// Aviso ao colaborador. O `WHERE NOT EXISTS` continua a existir como
	// segunda camada de idempotência (cobre também o caso sem event_id): não
	// se acumulam avisos por ler sobre o mesmo assunto.
	var notificacaoID int64
	notifErr := tx.QueryRow(ctx, `
		INSERT INTO notif_colaborador (tenant_id, user_id, tipo, titulo, corpo, link)
		SELECT $1, $2, 'biometria_reenroll',
		       'Registo facial desactualizado',
		       'O modelo de reconhecimento facial foi actualizado. Repita o registo do seu rosto para voltar a marcar ponto por reconhecimento facial.',
		       '/self-service/biometria'
		 WHERE NOT EXISTS (
		       SELECT 1 FROM notif_colaborador
		        WHERE user_id = $2 AND tenant_id = $1
		          AND tipo = 'biometria_reenroll' AND NOT lida
		 )
		RETURNING id`,
		in.TenantID, in.ErpUserID,
	).Scan(&notificacaoID)

	// Zero linhas = já existia um aviso por ler; não é erro.
	if notifErr != nil && !errors.Is(notifErr, pgx.ErrNoRows) {
		return reenrollWebhookResult{}, notifErr
	}

	return reenrollWebhookResult{Notified: notifErr == nil}, nil
}
