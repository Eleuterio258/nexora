package handlers

import (
	"net/http"
)

func (h *Handler) Dashboard(w http.ResponseWriter, r *http.Request) {
	var stats struct {
		TotalTenants     int `json:"total_tenants"`
		TenantsAtivos    int `json:"tenants_ativos"`
		TenantsSuspensos int `json:"tenants_suspensos"`
		TenantsInativos  int `json:"tenants_inativos"`
		TotalUtilizadores int `json:"total_utilizadores"`
		UtilizadoresAtivos int `json:"utilizadores_ativos"`
		TotalPlanos      int `json:"total_planos"`
	}

	err := h.db.QueryRow(r.Context(), `
		SELECT
			COUNT(*) FILTER (WHERE 1=1),
			COUNT(*) FILTER (WHERE status = 'ativo'),
			COUNT(*) FILTER (WHERE status = 'suspenso'),
			COUNT(*) FILTER (WHERE status = 'inativo')
		  FROM saas.tenants`).Scan(
		&stats.TotalTenants, &stats.TenantsAtivos, &stats.TenantsSuspensos, &stats.TenantsInativos,
	)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	err = h.db.QueryRow(r.Context(), `
		SELECT COUNT(*), COUNT(*) FILTER (WHERE estado = 'ativo')
		  FROM auth.users`).Scan(&stats.TotalUtilizadores, &stats.UtilizadoresAtivos)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	err = h.db.QueryRow(r.Context(), `SELECT COUNT(*) FROM saas.plans WHERE ativo = TRUE`).Scan(&stats.TotalPlanos)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, stats, http.StatusOK)
}
