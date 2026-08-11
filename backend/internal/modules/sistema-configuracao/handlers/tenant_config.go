package handlers

import (
	"encoding/json"
	"net/http"

	mw "nexora/internal/middleware"
)

// GET /api/system/branding
// Devolve o branding do tenant autenticado (logótipo, cores, contacto), ou
// campos vazios se o tenant nunca o tiver configurado — não é erro.
func (h *Handler) ObterBranding(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var logoURL, corPrimaria, corSecundaria, slogan, websiteURL, suporteEmail, suporteTelefone *string
	err := h.db.QueryRow(r.Context(), `
		SELECT logo_url, cor_primaria, cor_secundaria, slogan, website_url, suporte_email, suporte_telefone
		  FROM sistema_configuracao.tenant_branding WHERE tenant_id=$1`, user.TenantID).
		Scan(&logoURL, &corPrimaria, &corSecundaria, &slogan, &websiteURL, &suporteEmail, &suporteTelefone)
	if err != nil {
		jsonOK(w, map[string]any{
			"logo_url": nil, "cor_primaria": nil, "cor_secundaria": nil, "slogan": nil,
			"website_url": nil, "suporte_email": nil, "suporte_telefone": nil,
		}, http.StatusOK)
		return
	}
	jsonOK(w, map[string]any{
		"logo_url": logoURL, "cor_primaria": corPrimaria, "cor_secundaria": corSecundaria, "slogan": slogan,
		"website_url": websiteURL, "suporte_email": suporteEmail, "suporte_telefone": suporteTelefone,
	}, http.StatusOK)
}

// PUT /api/system/branding
// Protegido por RequirePermission(db, "sistema-configuracao", "editar_configuracoes").
func (h *Handler) GuardarBranding(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		LogoURL         *string `json:"logo_url"`
		CorPrimaria     *string `json:"cor_primaria"`
		CorSecundaria   *string `json:"cor_secundaria"`
		Slogan          *string `json:"slogan"`
		WebsiteURL      *string `json:"website_url"`
		SuporteEmail    *string `json:"suporte_email"`
		SuporteTelefone *string `json:"suporte_telefone"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}

	_, err := h.db.Exec(r.Context(), `
		INSERT INTO sistema_configuracao.tenant_branding
			(tenant_id, logo_url, cor_primaria, cor_secundaria, slogan, website_url, suporte_email, suporte_telefone, updated_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		ON CONFLICT (tenant_id) DO UPDATE SET
			logo_url=$2, cor_primaria=$3, cor_secundaria=$4, slogan=$5,
			website_url=$6, suporte_email=$7, suporte_telefone=$8, updated_by=$9, updated_at=NOW()`,
		user.TenantID, body.LogoURL, body.CorPrimaria, body.CorSecundaria, body.Slogan,
		body.WebsiteURL, body.SuporteEmail, body.SuporteTelefone, user.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/system/document-settings?modulo=&tipo_documento=
// Lista as configurações de numeração/layout de documentos do tenant,
// opcionalmente filtradas por módulo e/ou tipo de documento.
func (h *Handler) ListarDocumentSettings(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("modulo"); v != "" {
		args = append(args, v)
		where += " AND modulo=$" + itoa(int64(len(args)))
	}
	if v := q.Get("tipo_documento"); v != "" {
		args = append(args, v)
		where += " AND tipo_documento=$" + itoa(int64(len(args)))
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, modulo, tipo_documento, prefixo, reinicia_anualmente, serie_activa, layout_template
		  FROM sistema_configuracao.tenant_document_settings
		 WHERE `+where+`
		 ORDER BY modulo, tipo_documento`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID                 int64   `json:"id"`
		Modulo             string  `json:"modulo"`
		TipoDocumento      string  `json:"tipo_documento"`
		Prefixo            *string `json:"prefixo"`
		ReiniciaAnualmente bool    `json:"reinicia_anualmente"`
		SerieActiva        *string `json:"serie_activa"`
		LayoutTemplate     *string `json:"layout_template"`
	}
	data := []Row{}
	for rows.Next() {
		var d Row
		if rows.Scan(&d.ID, &d.Modulo, &d.TipoDocumento, &d.Prefixo, &d.ReiniciaAnualmente, &d.SerieActiva, &d.LayoutTemplate) == nil {
			data = append(data, d)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// PUT /api/system/document-settings
// Corpo: { "modulo", "tipo_documento", "prefixo", "reinicia_anualmente", "serie_activa", "layout_template" }
// Protegido por RequirePermission(db, "sistema-configuracao", "editar_configuracoes").
func (h *Handler) GuardarDocumentSetting(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Modulo             string  `json:"modulo"`
		TipoDocumento      string  `json:"tipo_documento"`
		Prefixo            *string `json:"prefixo"`
		ReiniciaAnualmente *bool   `json:"reinicia_anualmente"`
		SerieActiva        *string `json:"serie_activa"`
		LayoutTemplate     *string `json:"layout_template"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Modulo == "" || body.TipoDocumento == "" {
		jsonErr(w, "modulo e tipo_documento são obrigatórios", http.StatusBadRequest)
		return
	}
	reiniciaAnualmente := true
	if body.ReiniciaAnualmente != nil {
		reiniciaAnualmente = *body.ReiniciaAnualmente
	}

	_, err := h.db.Exec(r.Context(), `
		INSERT INTO sistema_configuracao.tenant_document_settings
			(tenant_id, modulo, tipo_documento, prefixo, reinicia_anualmente, serie_activa, layout_template, updated_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		ON CONFLICT (tenant_id, modulo, tipo_documento) DO UPDATE SET
			prefixo=$4, reinicia_anualmente=$5, serie_activa=$6, layout_template=$7, updated_by=$8, updated_at=NOW()`,
		user.TenantID, body.Modulo, body.TipoDocumento, body.Prefixo, reiniciaAnualmente, body.SerieActiva, body.LayoutTemplate, user.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
