package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ListarResultadosFuncionario devolve os resultados diários já calculados de
// um funcionário num intervalo de datas — GET
// /api/rh/funcionarios/{id}/resultados?data_inicio=&data_fim=.
func (h *Handler) ListarResultadosFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID := chi.URLParam(r, "id")

	dataInicio := r.URL.Query().Get("data_inicio")
	dataFim := r.URL.Query().Get("data_fim")
	if dataInicio == "" {
		dataInicio = time.Now().AddDate(0, 0, -30).Format("2006-01-02")
	}
	if dataFim == "" {
		dataFim = time.Now().Format("2006-01-02")
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT data_referencia, horas_trabalhadas, horas_normais, horas_extra, horas_nocturnas,
		       horas_remoto, horas_missao, horas_formacao, horas_intervalo, horas_nao_contabilizadas,
		       atraso_minutos, saida_antecipada_minutos, ausencia, falta_justificada, falta_injustificada,
		       versao_regra, recalculado_em
		  FROM rh.resultados_diarios
		 WHERE tenant_id = $1 AND funcionario_id = $2
		   AND data_referencia BETWEEN $3::date AND $4::date
		 ORDER BY data_referencia DESC`,
		user.TenantID, funcionarioID, dataInicio, dataFim)
	defer rows.Close()

	type row struct {
		DataReferencia         time.Time      `json:"data_referencia"`
		HorasTrabalhadas       *time.Duration `json:"horas_trabalhadas"`
		HorasNormais           *time.Duration `json:"horas_normais"`
		HorasExtra             *time.Duration `json:"horas_extra"`
		HorasNocturnas         *time.Duration `json:"horas_nocturnas"`
		HorasRemoto            *time.Duration `json:"horas_remoto"`
		HorasMissao            *time.Duration `json:"horas_missao"`
		HorasFormacao          *time.Duration `json:"horas_formacao"`
		HorasIntervalo         *time.Duration `json:"horas_intervalo"`
		HorasNaoContabilizadas *time.Duration `json:"horas_nao_contabilizadas"`
		AtrasoMinutos          int32          `json:"atraso_minutos"`
		SaidaAntecipadaMinutos int32          `json:"saida_antecipada_minutos"`
		Ausencia               bool           `json:"ausencia"`
		FaltaJustificada       bool           `json:"falta_justificada"`
		FaltaInjustificada     bool           `json:"falta_injustificada"`
		VersaoRegra            int32          `json:"versao_regra"`
		RecalculadoEm          *time.Time     `json:"recalculado_em"`
	}
	data := []row{}
	for rows.Next() {
		var res row
		if rows.Scan(&res.DataReferencia, &res.HorasTrabalhadas, &res.HorasNormais, &res.HorasExtra, &res.HorasNocturnas,
			&res.HorasRemoto, &res.HorasMissao, &res.HorasFormacao, &res.HorasIntervalo, &res.HorasNaoContabilizadas,
			&res.AtrasoMinutos, &res.SaidaAntecipadaMinutos, &res.Ausencia, &res.FaltaJustificada, &res.FaltaInjustificada,
			&res.VersaoRegra, &res.RecalculadoEm) == nil {
			data = append(data, res)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// RecalcularResultadoFuncionario força o recálculo do resultado diário de um
// funcionário numa data — POST /api/rh/funcionarios/{id}/recalcular
// {"data": "2026-07-20"}. Útil depois de uma correcção aprovada ou de uma
// mudança de regra.
func (h *Handler) RecalcularResultadoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcionarioID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "id de funcionário inválido", http.StatusBadRequest)
		return
	}

	if !h.podeGerirFuncionario(r, funcionarioID) {
		jsonErr(w, "Sem permissão para recalcular este funcionário", http.StatusForbidden)
		return
	}

	var body struct {
		Data string `json:"data"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	data := time.Now()
	if body.Data != "" {
		if d, err := time.Parse("2006-01-02", body.Data); err == nil {
			data = d
		}
	}

	resultado, err := h.assiduidade.RecalcularDia(r.Context(), user.TenantID, funcionarioID, data)
	if err != nil {
		jsonErr(w, "Erro ao recalcular resultado", http.StatusInternalServerError)
		return
	}
	jsonOK(w, resultado, http.StatusOK)
}
