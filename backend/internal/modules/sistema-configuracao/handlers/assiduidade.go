package handlers

import (
	"encoding/json"
	"net/http"

	mw "nexora/internal/middleware"
)

// GET /api/system/configuracao/tenant/feature/rh.assiduidade
// Devolve a configuração de métodos de assiduidade do tenant autenticado:
// override em sistema_configuracao.tenant_feature_flags, ou o valor por
// defeito do catálogo se o tenant nunca a tiver configurado.
func (h *Handler) ObterConfigAssiduidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var activo bool
	var configuracao json.RawMessage
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(tf.activo, fc.ativo_por_defeito), COALESCE(tf.configuracao, '{}'::jsonb)
		  FROM saas.feature_catalog fc
		  LEFT JOIN sistema_configuracao.tenant_feature_flags tf
		    ON tf.tenant_id = $1 AND tf.codigo = fc.key
		 WHERE fc.key = 'rh.assiduidade'`, user.TenantID).
		Scan(&activo, &configuracao)
	if err != nil {
		jsonErr(w, "Feature rh.assiduidade não encontrada no catálogo", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{
		"activo":       activo,
		"configuracao": configuracao,
	}, http.StatusOK)
}

// PUT /api/system/configuracao/tenant/feature/rh.assiduidade
// Corpo: { "activo": bool, "configuracao": {...} }
// Protegido por RequirePermission(db, "sistema-configuracao", "editar_configuracoes").
func (h *Handler) GuardarConfigAssiduidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Activo       bool            `json:"activo"`
		Configuracao json.RawMessage `json:"configuracao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if len(body.Configuracao) == 0 {
		body.Configuracao = json.RawMessage("{}")
	}

	_, err := h.db.Exec(r.Context(), `
		INSERT INTO sistema_configuracao.tenant_feature_flags
			(tenant_id, codigo, modulo, activo, configuracao, updated_by)
		VALUES ($1, 'rh.assiduidade', 'recursos-humanos', $2, $3, $4)
		ON CONFLICT ON CONSTRAINT uq_tenant_feature_flags
		DO UPDATE SET activo = $2, configuracao = $3, updated_by = $4, updated_at = NOW()`,
		user.TenantID, body.Activo, body.Configuracao, user.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
