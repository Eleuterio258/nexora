package handlers

import (
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

	// user_id fica NULL: o actor é um dispositivo, não uma conta de utilizador,
	// e audit_logs.user_id é lido/indexado como auth.users.id. A identificação
	// do dispositivo vai em `detalhes`.
	if _, err := h.db.Exec(r.Context(), `
		INSERT INTO auditoria.audit_logs (tenant_id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address)
		VALUES ($1, NULL, 'recursos-humanos', 'biometria_facial', $2, 'reenroll_required', $3, $4)`,
		tenantID, funcionarioID, detalhes, r.RemoteAddr,
	); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Aviso ao colaborador. O `WHERE NOT EXISTS` torna a operação idempotente:
	// se o FaceClock repetir a notificação (retry, ou o template voltar a
	// transitar para PENDING_REENROLL depois de outro enrolamento falhado),
	// não se acumulam avisos por ler sobre o mesmo assunto.
	var notificacaoID int64
	err = h.db.QueryRow(r.Context(), `
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
		tenantID, erpUserID,
	).Scan(&notificacaoID)

	// Zero linhas = já existia um aviso por ler; não é erro.
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"funcionario_id": funcionarioID,
		"notificado":     err == nil,
	}, http.StatusAccepted)
}
