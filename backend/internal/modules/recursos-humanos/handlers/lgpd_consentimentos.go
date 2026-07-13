package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	mw "nexora/internal/middleware"
)

// ── Consentimentos LGPD (recolha de dados biométricos) ──────────────────────
//
// Autenticados via RequireDeviceAuth (X-API-Key), tal como os restantes
// endpoints de assiduidade/{config,funcionarios,geofence} — o FaceClock
// submete/consulta em nome do erp_user_id indicado no pedido, porque o
// consentimento é capturado no momento do enrolamento biométrico na app,
// antes de haver sessão ERP activa do próprio colaborador.
//
// erp_user_id é auth.users.id (o id numérico devolvido no login do ERP e
// guardado pela app — ver ErpUser.id/SessionManager.kt no nexora_assiduidade),
// NÃO rh.funcionarios.id. Resolve-se para funcionario_id via
// resolverFuncionarioPorUserID, mesmo padrão do funcionarioID() do
// self-service (handler.go), só que aqui o id vem do pedido em vez do JWT
// (o device não tem sessão do colaborador).

type consentimentoRow struct {
	ID            int64      `json:"id"`
	FuncionarioID int64      `json:"funcionario_id"`
	TermoVersao   string     `json:"termo_versao"`
	TermoHash     string     `json:"termo_hash"`
	AceiteEm      time.Time  `json:"aceite_em"`
	RevogadoEm    *time.Time `json:"revogado_em"`
	CreatedAt     time.Time  `json:"created_at"`
}

// resolverFuncionarioPorUserID traduz auth.users.id (erp_user_id, tal como a
// app o conhece) para rh.funcionarios.id, dentro do tenant resolvido.
func (h *Handler) resolverFuncionarioPorUserID(r *http.Request, erpUserID string, tenantID int64) (int64, bool) {
	var funcionarioID int64
	err := h.db.QueryRow(r.Context(),
		`SELECT id FROM rh.funcionarios WHERE user_id=$1 AND tenant_id=$2`,
		erpUserID, tenantID).Scan(&funcionarioID)
	return funcionarioID, err == nil
}

// POST /api/hardware/assiduidade/consentimentos
// Regista um novo consentimento e revoga automaticamente qualquer
// consentimento anterior ainda activo do mesmo funcionário (aceitar uma nova
// versão dos termos substitui a anterior).
func (h *Handler) CriarConsentimentoDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body struct {
		ErpUserID   string    `json:"erp_user_id"`
		TermoVersao string    `json:"termo_versao"`
		TermoHash   string    `json:"termo_hash"`
		AceiteEm    time.Time `json:"aceite_em"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ErpUserID == "" || body.TermoVersao == "" || body.TermoHash == "" {
		jsonErr(w, "erp_user_id, termo_versao e termo_hash são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.AceiteEm.IsZero() {
		body.AceiteEm = time.Now()
	}
	funcionarioID, ok := h.resolverFuncionarioPorUserID(r, body.ErpUserID, tenantID)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	if _, err := tx.Exec(r.Context(), `
		UPDATE lgpd.consentimentos SET revogado_em = NOW()
		 WHERE funcionario_id=$1 AND tenant_id=$2 AND revogado_em IS NULL`,
		funcionarioID, tenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var id int64
	if err := tx.QueryRow(r.Context(), `
		INSERT INTO lgpd.consentimentos (tenant_id, funcionario_id, termo_versao, termo_hash, aceite_em, ip_address)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		tenantID, funcionarioID, body.TermoVersao, body.TermoHash, body.AceiteEm, r.RemoteAddr,
	).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// GET /api/hardware/assiduidade/consentimentos/activo?erp_user_id=
func (h *Handler) ObterConsentimentoActivoDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}
	erpUserID := r.URL.Query().Get("erp_user_id")
	if erpUserID == "" {
		jsonErr(w, "erp_user_id é obrigatório", http.StatusBadRequest)
		return
	}
	funcionarioID, ok := h.resolverFuncionarioPorUserID(r, erpUserID, tenantID)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	var c consentimentoRow
	err = h.db.QueryRow(r.Context(), `
		SELECT id, funcionario_id, termo_versao, termo_hash, aceite_em, revogado_em, created_at
		  FROM lgpd.consentimentos
		 WHERE funcionario_id=$1 AND tenant_id=$2 AND revogado_em IS NULL
		 ORDER BY aceite_em DESC LIMIT 1`, funcionarioID, tenantID).
		Scan(&c.ID, &c.FuncionarioID, &c.TermoVersao, &c.TermoHash, &c.AceiteEm, &c.RevogadoEm, &c.CreatedAt)
	if err != nil {
		jsonErr(w, "Nenhum consentimento activo encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, c, http.StatusOK)
}

// GET /api/hardware/assiduidade/consentimentos?erp_user_id=
func (h *Handler) ListarConsentimentosDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}
	erpUserID := r.URL.Query().Get("erp_user_id")
	if erpUserID == "" {
		jsonErr(w, "erp_user_id é obrigatório", http.StatusBadRequest)
		return
	}
	funcionarioID, ok := h.resolverFuncionarioPorUserID(r, erpUserID, tenantID)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT id, funcionario_id, termo_versao, termo_hash, aceite_em, revogado_em, created_at
		  FROM lgpd.consentimentos
		 WHERE funcionario_id=$1 AND tenant_id=$2
		 ORDER BY aceite_em DESC LIMIT 100`, funcionarioID, tenantID)
	if rows == nil {
		jsonOK(w, []consentimentoRow{}, http.StatusOK)
		return
	}
	defer rows.Close()

	data := []consentimentoRow{}
	for rows.Next() {
		var c consentimentoRow
		if rows.Scan(&c.ID, &c.FuncionarioID, &c.TermoVersao, &c.TermoHash, &c.AceiteEm, &c.RevogadoEm, &c.CreatedAt) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// POST /api/hardware/assiduidade/consentimentos/revogar
// Revoga o(s) consentimento(s) activo(s) do funcionário indicado — chamado
// quando o colaborador retira o consentimento ou exerce o direito ao
// esquecimento (POST /consents/users/{id}/revoke e
// DELETE /consents/users/{id}/biometric-data no FaceClock).
func (h *Handler) RevogarConsentimentoDevice(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tenantID, err := resolveSaasTenantID(h, r, user.TenantID)
	if err != nil {
		jsonErr(w, "Dispositivo sem empresa/tenant associado correctamente", http.StatusUnprocessableEntity)
		return
	}

	var body struct {
		ErpUserID string `json:"erp_user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ErpUserID == "" {
		jsonErr(w, "erp_user_id é obrigatório", http.StatusBadRequest)
		return
	}
	funcionarioID, ok := h.resolverFuncionarioPorUserID(r, body.ErpUserID, tenantID)
	if !ok {
		jsonErr(w, "Funcionário não encontrado", http.StatusNotFound)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE lgpd.consentimentos SET revogado_em = NOW()
		 WHERE funcionario_id=$1 AND tenant_id=$2 AND revogado_em IS NULL`,
		funcionarioID, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"revoked": tag.RowsAffected()}, http.StatusOK)
}
