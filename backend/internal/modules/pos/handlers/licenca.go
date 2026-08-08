package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	mw "nexora/internal/middleware"
)

// ValidarLicencaApp é um endpoint público usado pelo app PayCore Mobile na
// primeira activação. Recebe uma chave de licença (XXXX-XXXX-XXXX-XXXX),
// procura em empresas.company_licenses e, se válida, devolve os dados do
// tenant principal associado à empresa. Não requer autenticação.
func (h *Handler) ValidarLicencaApp(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Chave string `json:"chave"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Chave == "" {
		jsonErr(w, "chave é obrigatória", http.StatusBadRequest)
		return
	}

	type resultado struct {
		Valida  bool   `json:"valida"`
		Motivo  string `json:"motivo,omitempty"`
		Plano   string `json:"plano,omitempty"`
		Status  string `json:"status,omitempty"`
		ExpiraEm *time.Time `json:"expira_em,omitempty"`
		TenantID  *int64  `json:"tenant_id,omitempty"`
		TenantNome *string `json:"tenant_nome,omitempty"`
		TenantSlug *string `json:"tenant_slug,omitempty"`
	}

	var licencaID int64
	var companyID int64
	var plano, status string
	var expiraEm *time.Time
	err := h.db.QueryRow(r.Context(), `
		SELECT id, company_id, plano, status, expira_em
		  FROM empresas.company_licenses
		 WHERE licenca_chave = $1`, body.Chave).
		Scan(&licencaID, &companyID, &plano, &status, &expiraEm)
	if err != nil {
		jsonOK(w, resultado{Valida: false, Motivo: "Chave de licença inválida"}, http.StatusOK)
		return
	}

	ativa := status == "ativa" && (expiraEm == nil || expiraEm.After(time.Now().Add(-24*time.Hour)))
	if !ativa {
		motivo := "Licença inactiva"
		if status == "expirada" || (expiraEm != nil && expiraEm.Before(time.Now())) {
			motivo = "Licença expirada"
		} else if status == "suspensa" {
			motivo = "Licença suspensa"
		}
		jsonOK(w, resultado{
			Valida:   false,
			Motivo:   motivo,
			Plano:    plano,
			Status:   status,
			ExpiraEm: expiraEm,
		}, http.StatusOK)
		return
	}

	// Devolve o primeiro tenant activo da empresa como tenant principal.
	var tenantID int64
	var tenantNome, tenantSlug string
	err = h.db.QueryRow(r.Context(), `
		SELECT id, nome, slug FROM saas.tenants
		 WHERE company_id = $1 AND status = 'ativo'
		 ORDER BY id LIMIT 1`, companyID).
		Scan(&tenantID, &tenantNome, &tenantSlug)
	if err != nil {
		jsonOK(w, resultado{
			Valida: false,
			Motivo: "Licença válida mas sem tenant activo associado",
			Plano:  plano,
			Status: status,
		}, http.StatusOK)
		return
	}

	jsonOK(w, resultado{
		Valida:     true,
		Plano:      plano,
		Status:     status,
		ExpiraEm:   expiraEm,
		TenantID:   &tenantID,
		TenantNome: &tenantNome,
		TenantSlug: &tenantSlug,
	}, http.StatusOK)
}

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
