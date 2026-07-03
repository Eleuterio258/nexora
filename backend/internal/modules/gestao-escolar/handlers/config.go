package handlers

import (
	"encoding/json"
	"net/http"

	mw "nexora/internal/middleware"
)

// configFinanceira payload para inicializar/actualizar configuração financeira escolar.
type configFinanceira struct {
	ContaBancariaID          *int64 `json:"conta_bancaria_id"`
	CentroCustoID            *int64 `json:"centro_custo_id"`
	CriarMovimentoTesouraria bool   `json:"criar_movimento_tesouraria"`
	CriarMovimentoFinanceiro bool   `json:"criar_movimento_financeiro"`
}

// ObterConfigFinanceira devolve a configuração financeira do tenant.
func (h *Handler) ObterConfigFinanceira(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var cfg configFinanceira
	err := h.db.QueryRow(r.Context(), `
		SELECT conta_bancaria_id, centro_custo_id,
		       criar_movimento_tesouraria, criar_movimento_financeiro
		FROM gestao_escolar.school_financial_config
		WHERE tenant_id = $1`, u.TenantID,
	).Scan(&cfg.ContaBancariaID, &cfg.CentroCustoID,
		&cfg.CriarMovimentoTesouraria, &cfg.CriarMovimentoFinanceiro)
	if err != nil {
		// Sem configuração — devolve valores padrão
		jsonOK(w, configFinanceira{}, http.StatusOK)
		return
	}
	jsonOK(w, cfg, http.StatusOK)
}

// GravarConfigFinanceira cria ou actualiza a configuração financeira do tenant (upsert).
func (h *Handler) GravarConfigFinanceira(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input configFinanceira
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	_, err := h.db.Exec(r.Context(), `
		INSERT INTO gestao_escolar.school_financial_config
		(tenant_id, conta_bancaria_id, centro_custo_id,
		 criar_movimento_tesouraria, criar_movimento_financeiro)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (tenant_id) DO UPDATE SET
		  conta_bancaria_id          = EXCLUDED.conta_bancaria_id,
		  centro_custo_id            = EXCLUDED.centro_custo_id,
		  criar_movimento_tesouraria = EXCLUDED.criar_movimento_tesouraria,
		  criar_movimento_financeiro = EXCLUDED.criar_movimento_financeiro,
		  updated_at                 = NOW()`,
		u.TenantID, input.ContaBancariaID, input.CentroCustoID,
		input.CriarMovimentoTesouraria, input.CriarMovimentoFinanceiro,
	)
	if err != nil {
		jsonErr(w, "Erro ao gravar configuracao", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
