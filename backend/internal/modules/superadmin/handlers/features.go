package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
)

// ── Catálogo ───────────────────────────────────────────────────────────────────

// GET /api/superadmin/features/catalog
// Lista todo o catálogo de features agrupado por módulo.
func (h *Handler) ListarFeatureCatalog(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(r.Context(), `
		SELECT key, modulo, nome, COALESCE(descricao,''), ativo_por_defeito, configuravel
		  FROM saas.feature_catalog
		 ORDER BY modulo, key`)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		Key              string `json:"key"`
		Modulo           string `json:"modulo"`
		Nome             string `json:"nome"`
		Descricao        string `json:"descricao"`
		AtivoPorDefeito  bool   `json:"ativo_por_defeito"`
		Configuravel     bool   `json:"configuravel"`
	}
	data := []Row{}
	for rows.Next() {
		var r Row
		if rows.Scan(&r.Key, &r.Modulo, &r.Nome, &r.Descricao, &r.AtivoPorDefeito, &r.Configuravel) == nil {
			data = append(data, r)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ── Features por tenant (superadmin vê e altera qualquer tenant) ───────────────

// GET /api/superadmin/features/tenants/{tenantId}
// Devolve o estado de cada feature para o tenant (override ou valor por defeito).
func (h *Handler) ListarFeaturesTenant(w http.ResponseWriter, r *http.Request) {
	tenantID := chi.URLParam(r, "tenantId")

	rows, err := h.db.Query(r.Context(), `
		SELECT fc.key, fc.modulo, fc.nome, fc.configuravel,
		       COALESCE(tf.activo, fc.ativo_por_defeito) AS activo,
		       (tf.codigo IS NOT NULL) AS tem_override
		  FROM saas.feature_catalog fc
		  LEFT JOIN sistema_configuracao.tenant_feature_flags tf
		    ON tf.tenant_id = $1 AND tf.codigo = fc.key
		 ORDER BY fc.modulo, fc.key`, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		Key         string `json:"key"`
		Modulo      string `json:"modulo"`
		Nome        string `json:"nome"`
		Configuravel bool  `json:"configuravel"`
		Activo      bool   `json:"activo"`
		TemOverride bool   `json:"tem_override"`
	}
	data := []Row{}
	for rows.Next() {
		var r Row
		if rows.Scan(&r.Key, &r.Modulo, &r.Nome, &r.Configuravel, &r.Activo, &r.TemOverride) == nil {
			data = append(data, r)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// POST /api/superadmin/features/tenants/{tenantId}/{key}
// Corpo: { "activo": true|false }
// Superadmin pode alterar qualquer feature, mesmo as não configuráveis.
func (h *Handler) AlterarFeatureTenant(w http.ResponseWriter, r *http.Request) {
	tenantID, err := strconv.ParseInt(chi.URLParam(r, "tenantId"), 10, 64)
	if err != nil {
		jsonErr(w, "tenantId inválido", http.StatusBadRequest)
		return
	}
	key := chi.URLParam(r, "key")

	var body struct {
		Activo bool `json:"activo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}

	// Verificar que a feature existe no catálogo
	var exists bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM saas.feature_catalog WHERE key = $1)`, key).Scan(&exists)
	if !exists {
		jsonErr(w, "Feature não encontrada no catálogo", http.StatusNotFound)
		return
	}

	_, err = h.db.Exec(r.Context(), `
		INSERT INTO sistema_configuracao.tenant_feature_flags (tenant_id, codigo, activo)
		VALUES ($1, $2, $3)
		ON CONFLICT ON CONSTRAINT uq_tenant_feature_flags
		DO UPDATE SET activo = $3, updated_at = NOW()`,
		tenantID, key, body.Activo)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Invalidar cache de permissões dos utilizadores do tenant
	_, _ = h.db.Exec(r.Context(),
		`UPDATE auth.users SET permissoes_atualizadas_em = NOW()
		 WHERE id IN (SELECT user_id FROM auth.memberships WHERE tenant_id = $1)`,
		tenantID)

	w.WriteHeader(http.StatusNoContent)
}

// DELETE /api/superadmin/features/tenants/{tenantId}/{key}
// Remove o override e repõe o valor por defeito do catálogo.
func (h *Handler) ReporFeatureTenant(w http.ResponseWriter, r *http.Request) {
	tenantID := chi.URLParam(r, "tenantId")
	key := chi.URLParam(r, "key")

	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM sistema_configuracao.tenant_feature_flags
		 WHERE tenant_id = $1 AND codigo = $2`, tenantID, key)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Override não encontrado", http.StatusNotFound)
		return
	}

	_, _ = h.db.Exec(r.Context(),
		`UPDATE auth.users SET permissoes_atualizadas_em = NOW()
		 WHERE id IN (SELECT user_id FROM auth.memberships WHERE tenant_id = $1)`,
		tenantID)

	w.WriteHeader(http.StatusNoContent)
}
