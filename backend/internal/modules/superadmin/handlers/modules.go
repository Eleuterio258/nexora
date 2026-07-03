package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

type moduloCatalogRow struct {
	Key       string `json:"key"`
	Nome      string `json:"nome"`
	Categoria string `json:"categoria"`
	Icone     string `json:"icone,omitempty"`
	Ativo     bool   `json:"ativo"`
}

type tenantModuleResponse struct {
	TenantID  int64          `json:"tenant_id"`
	Modulo    string         `json:"modulo"`
	Ativo     bool           `json:"ativo"`
	Config    map[string]any `json:"config"`
	UpdatedAt time.Time      `json:"updated_at"`
}

func (h *Handler) ListarModulosTenant(w http.ResponseWriter, r *http.Request) {
	tenantID := chi.URLParam(r, "tenantId")

	rows, err := h.db.Query(r.Context(), `
		SELECT tenant_id, modulo, ativo, config, updated_at
		  FROM saas.tenant_modules
		 WHERE tenant_id = $1
		 ORDER BY modulo ASC`, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []tenantModuleResponse{}
	for rows.Next() {
		var m tenantModuleResponse
		if err := rows.Scan(&m.TenantID, &m.Modulo, &m.Ativo, &m.Config, &m.UpdatedAt); err == nil {
			data = append(data, m)
		}
	}

	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ActualizarModuloTenant(w http.ResponseWriter, r *http.Request) {
	tenantID, err := strconv.ParseInt(chi.URLParam(r, "tenantId"), 10, 64)
	if err != nil {
		jsonErr(w, "tenantId inválido", http.StatusBadRequest)
		return
	}
	modulo := chi.URLParam(r, "modulo")

	var body struct {
		Ativo  *bool          `json:"ativo"`
		Config map[string]any `json:"config"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}

	// Ao DESACTIVAR: verificar se algum módulo activo deste tenant depende deste.
	if body.Ativo != nil && !*body.Ativo {
		dependentes, err := modulosDependentes(r.Context(), h.db, tenantID, modulo)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if len(dependentes) > 0 {
			jsonErr(w, "Não é possível desactivar: os módulos "+joinStrings(dependentes)+" dependem deste módulo", http.StatusConflict)
			return
		}
	}

	// Ao ACTIVAR: validar entitlement do plano + resolver dependências em cascata.
	var activatedAlso []string
	if body.Ativo == nil || *body.Ativo {
		// Verificar se o plano do tenant inclui este módulo.
		// Se o tenant não tiver plano, o superadmin pode activar sem restrição.
		var planoID *int64
		h.db.QueryRow(r.Context(), `SELECT plano_id FROM saas.tenants WHERE id = $1`, tenantID).Scan(&planoID)
		if planoID != nil {
			var permitido bool
			h.db.QueryRow(r.Context(),
				`SELECT EXISTS(SELECT 1 FROM saas.plan_modules WHERE plan_id = $1 AND modulo = $2)`,
				*planoID, modulo).Scan(&permitido)
			if !permitido {
				jsonErr(w, "Módulo não incluído no plano do tenant", http.StatusPaymentRequired)
				return
			}
		}

		cascata, err := resolverCascata(r.Context(), h.db, modulo)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		for _, dep := range cascata {
			_, _ = h.db.Exec(r.Context(), `
				INSERT INTO saas.tenant_modules (tenant_id, modulo, ativo)
				VALUES ($1, $2, TRUE)
				ON CONFLICT (tenant_id, modulo) DO UPDATE SET ativo = TRUE, updated_at = NOW()`,
				tenantID, dep)
		}
		activatedAlso = cascata
	}

	var m tenantModuleResponse
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO saas.tenant_modules (tenant_id, modulo, ativo, config)
		VALUES ($1, $2, COALESCE($3, TRUE), COALESCE($4, '{}'::jsonb))
		ON CONFLICT (tenant_id, modulo)
		DO UPDATE SET
			ativo      = COALESCE($3, saas.tenant_modules.ativo),
			config     = COALESCE($4, saas.tenant_modules.config),
			updated_at = NOW()
		RETURNING tenant_id, modulo, ativo, config, updated_at`,
		tenantID, modulo, body.Ativo, body.Config).
		Scan(&m.TenantID, &m.Modulo, &m.Ativo, &m.Config, &m.UpdatedAt)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Invalida cache de permissões de todos os utilizadores do tenant.
	if _, err = h.db.Exec(r.Context(),
		`UPDATE users SET permissoes_atualizadas_em = NOW()
		 WHERE id IN (SELECT user_id FROM auth.memberships WHERE tenant_id = $1)`,
		tenantID); err != nil {
		// Não fatal — módulo já foi actualizado; próxima requisição do utilizador fará sync
		_ = err
	}

	type resp struct {
		tenantModuleResponse
		ActivatedAlso []string `json:"activated_also,omitempty"`
	}
	jsonOK(w, resp{m, activatedAlso}, http.StatusOK)
}

func joinStrings(ss []string) string {
	var b strings.Builder
	for i, s := range ss {
		if i > 0 {
			b.WriteString(", ")
		}
		b.WriteString(s)
	}
	return b.String()
}

func (h *Handler) ListarModulosDisponiveis(w http.ResponseWriter, r *http.Request) {
	type Row struct {
		moduloCatalogRow
		Requer []string `json:"requer"`
	}

	// Query 1: módulos
	rows, err := h.db.Query(r.Context(), `
		SELECT key, nome, categoria, COALESCE(icone, ''), ativo
		  FROM saas.module_catalog
		 WHERE ativo = TRUE
		 ORDER BY categoria, nome`)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []Row{}
	index := map[string]int{} // key → posição em data
	for rows.Next() {
		var r Row
		r.Requer = []string{}
		if rows.Scan(&r.Key, &r.Nome, &r.Categoria, &r.Icone, &r.Ativo) == nil {
			index[r.Key] = len(data)
			data = append(data, r)
		}
	}
	rows.Close()

	// Query 2: dependências — scan simples de strings
	deps, err := h.db.Query(r.Context(),
		`SELECT modulo, requires FROM saas.module_dependencies ORDER BY modulo, requires`)
	if err == nil {
		defer deps.Close()
		for deps.Next() {
			var modulo, req string
			if deps.Scan(&modulo, &req) == nil {
				if i, ok := index[modulo]; ok {
					data[i].Requer = append(data[i].Requer, req)
				}
			}
		}
	}

	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ResetarModulosTenant(w http.ResponseWriter, r *http.Request) {
	tenantID, _ := strconv.ParseInt(chi.URLParam(r, "tenantId"), 10, 64)

	_, err := h.db.Exec(r.Context(), `DELETE FROM saas.tenant_modules WHERE tenant_id = $1`, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	_, _ = h.db.Exec(r.Context(),
		`UPDATE users SET permissoes_atualizadas_em = NOW()
		 WHERE id IN (SELECT user_id FROM auth.memberships WHERE tenant_id = $1)`,
		tenantID)

	jsonOK(w, map[string]string{"message": "Módulos resetados"}, http.StatusOK)
}
