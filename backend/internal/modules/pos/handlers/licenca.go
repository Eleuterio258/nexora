package handlers

import (
	"net/http"
	"time"

	mw "nexora/internal/middleware"
)

// ObterLicenca devolve o estado da(s) licença(s) de aplicação do tenant do
// chamador — para o app poder mostrar avisos de expiração com antecedência
// e, quando bloqueado (ver mw.RequireLicencaAtiva, montado no resto do
// módulo POS), explicar porquê em vez de só receber 402 sem contexto.
// Fica de propósito fora desse bloqueio: mesmo com a licença expirada, o
// app continua a conseguir perguntar "porque estou bloqueado".
func (h *Handler) ObterLicenca(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	type licencaRow struct {
		Plano          string     `json:"plano"`
		Status         string     `json:"status"`
		LicencaChave   *string    `json:"licenca_chave"`
		LimiteUsuarios *int       `json:"limite_usuarios"`
		IniciaEm       time.Time  `json:"inicia_em"`
		ExpiraEm       *time.Time `json:"expira_em"`
		// Mesma condição usada por mw.RequireLicencaAtiva — calculada em SQL
		// para os dois nunca poderem divergir.
		Ativa bool `json:"ativa"`
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT l.plano, l.status, l.licenca_chave, l.limite_usuarios, l.inicia_em, l.expira_em,
		       (l.status = 'ativa' AND (l.expira_em IS NULL OR l.expira_em >= CURRENT_DATE))
		  FROM empresas.company_licenses l
		  JOIN saas.tenants t ON t.company_id = l.company_id
		 WHERE t.id = $1
		 ORDER BY l.expira_em DESC NULLS FIRST, l.id DESC`, user.TenantID)
	defer rows.Close()

	licencas := []licencaRow{}
	temAtiva := false
	for rows.Next() {
		var lic licencaRow
		if rows.Scan(&lic.Plano, &lic.Status, &lic.LicencaChave, &lic.LimiteUsuarios, &lic.IniciaEm, &lic.ExpiraEm, &lic.Ativa) == nil {
			licencas = append(licencas, lic)
			if lic.Ativa {
				temAtiva = true
			}
		}
	}

	// Sem nenhuma licença registada = licenciamento não é aplicado a este
	// tenant (retrocompatibilidade — ver RequireLicencaAtiva).
	bloqueado := len(licencas) > 0 && !temAtiva

	jsonOK(w, map[string]any{
		"licencas":  licencas,
		"bloqueado": bloqueado,
	}, http.StatusOK)
}
