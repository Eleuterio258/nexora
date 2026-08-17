package handlers

import (
	"encoding/json"
	"net/http"

	mw "nexora/internal/middleware"
)

// ObterConfiguracaoPOS devolve as configurações operacionais do POS para o tenant.
func (h *Handler) ObterConfiguracaoPOS(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	type Row struct {
		IvaPadrao         float64 `json:"iva_padrao"`
		SerieVenda        *string `json:"serie_venda"`
		SerieNotaCredito  *string `json:"serie_nota_credito"`
		ReciboAuto        bool    `json:"recibo_auto"`
		UpdatedAt         *string `json:"updated_at,omitempty"`
	}
	var c Row
	err := h.db.QueryRow(r.Context(), `
		SELECT iva_padrao, serie_venda, serie_nota_credito, recibo_auto, updated_at
		  FROM pos.pos_configuracao
		 WHERE tenant_id=$1`, user.TenantID).
		Scan(&c.IvaPadrao, &c.SerieVenda, &c.SerieNotaCredito, &c.ReciboAuto, &c.UpdatedAt)
	if err != nil {
		// Se não existe configuração, devolve valores por omissão.
		jsonOK(w, map[string]any{
			"iva_padrao":          17.0,
			"serie_venda":         nil,
			"serie_nota_credito":  nil,
			"recibo_auto":         true,
			"updated_at":          nil,
		}, http.StatusOK)
		return
	}
	jsonOK(w, c, http.StatusOK)
}

// GuardarConfiguracaoPOS actualiza as configurações operacionais do POS.
func (h *Handler) GuardarConfiguracaoPOS(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body struct {
		IvaPadrao        float64 `json:"iva_padrao"`
		SerieVenda       *string `json:"serie_venda"`
		SerieNotaCredito *string `json:"serie_nota_credito"`
		ReciboAuto       *bool   `json:"recibo_auto"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}
	if body.IvaPadrao < 0 || body.IvaPadrao > 100 {
		jsonErr(w, "IVA padrão deve estar entre 0 e 100", http.StatusBadRequest)
		return
	}

	reciboAuto := true
	if body.ReciboAuto != nil {
		reciboAuto = *body.ReciboAuto
	}

	_, err := h.db.Exec(r.Context(), `
		INSERT INTO pos.pos_configuracao (tenant_id, iva_padrao, serie_venda, serie_nota_credito, recibo_auto, updated_by)
		VALUES ($1,$2,$3,$4,$5,$6)
		ON CONFLICT (tenant_id) DO UPDATE SET
			iva_padrao=$2, serie_venda=$3, serie_nota_credito=$4, recibo_auto=$5, updated_by=$6, updated_at=NOW()`,
		user.TenantID, body.IvaPadrao, body.SerieVenda, body.SerieNotaCredito, reciboAuto, user.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
